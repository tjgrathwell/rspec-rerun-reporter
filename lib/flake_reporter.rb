require 'sqlite3'

class FlakeReporter
  attr_reader :db
  attr_reader :file_paths

  def initialize(file_paths = {})
    @file_paths = file_paths
    file_paths[:db] ||= 'tmp/test_flakes.sqlite3'
    file_paths[:id_name_map] ||= 'tmp/rspec_id_to_name_map.yml'
    file_paths[:status_persistence] ||= 'tmp/rspec_examples.txt'

    @db = SQLite3::Database.new(file_paths[:db])
    @db.results_as_hash = true

    create_schema

    @failed_tests = []
  end

  def add_flakes_from_persistance_file
    @failed_tests += failures_from_persistence_file(Time.now)
  end

  def persist_flakes
    @failed_tests.each do |flake_spec|
      db.execute(
        "INSERT INTO test_flakes (example_id, example_name, flaked_on, finished_on) VALUES (?, ?, ?, STRFTIME('%s', 'now'))",
        [flake_spec[:example_id], flake_spec[:example_name], flake_spec[:time].to_i]
      )
    end
  end

  def report_flakes(duration = :day)
    rows = db.execute(
      "SELECT * FROM test_flakes WHERE finished_on > ? AND finished_on < ?",
      Time.now.to_i - duration_seconds(duration), Time.now.to_i
    )

    if rows.length == 0
      puts "No recent flaky tests in the last #{duration}!"
      return
    end

    puts "Recent flaky tests in the last #{duration}:"

    names_for_examples = rows.each_with_object({}) do |r, hsh|
      hsh[r['example_id']] = r['example_name']
    end

    aggregate_counts = rows.each_with_object(Hash.new { 0 }) do |r, hsh|
      hsh[r['example_id']] += 1
    end

    invert_counts_hash(aggregate_counts).each do |count, flaky_test_ids|
      puts "Tests with #{count} #{count == 1 ? 'flake' : 'flakes'}:"
      flaky_test_ids.each do |flaky_test_id|
        puts "  #{flaky_test_id} # #{names_for_examples[flaky_test_id]}"
      end
    end
  end

  private

  def duration_seconds(duration_symbol)
    if duration_symbol == :day
      24 * 60 * 60
    elsif duration_symbol == :week
      24 * 60 * 60 * 7
    else
      raise RuntimeError.new("Unknown duration: #{duration_symbol}")
    end
  end

  def invert_counts_hash(counts_hash)
    counts_hash.each_with_object(Hash.new { |h,k| h[k] = [] }) do |(key,value),out|
      out[value] << key
    end
  end

  def name_map
    result = {}
    if File.exists?(file_paths[:id_name_map])
      result = YAML.load(File.read(file_paths[:id_name_map]))
    end
    result
  end

  def failures_from_persistence_file(flake_time)
    File.readlines(file_paths[:status_persistence])[2..-1].map do |l|
      l.split('|').map(&:strip)
    end.select do |file_ref|
      file_ref[1] == 'failed'
    end.map do |file_ref|
      example_name = file_ref[0]
      {
        example_id: example_name,
        example_name: name_map[example_name],
        time: flake_time
      }
    end
  end

  def create_schema
    db.execute <<~SQL
      CREATE TABLE IF NOT EXISTS test_flakes (
        example_id text,
        example_name text,
        flaked_on integer,
        finished_on integer
      )
    SQL
  end
end