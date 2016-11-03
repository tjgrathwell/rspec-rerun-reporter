require 'sqlite3'
require_relative 'persisters/sqlite_flake_persister'

class FlakeReporter
  attr_reader :db
  attr_reader :file_paths

  def initialize(file_paths = {})
    @file_paths = file_paths
    file_paths[:db] ||= 'tmp/test_flakes.sqlite3'
    file_paths[:id_name_map] ||= 'tmp/rspec_id_to_name_map.yml'
    file_paths[:status_persistence] ||= 'tmp/rspec_examples.txt'

    @persister = SqliteFlakePersister.new(file_paths[:db])

    @failed_tests = []
  end

  def add_flakes_from_persistance_file
    @failed_tests += failures_from_persistence_file(Time.now)
  end

  def persist_flakes
    @failed_tests.each do |flake_spec|
      @persister.persist_flake(flake_spec)
    end
  end

  def report_flakes(duration = :day)
    rows = @persister.flakes_since(Time.now.to_i - duration_seconds(duration))

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
    failure_file_parser = FailureFileParser.new(file_paths[:status_persistence])
    failure_file_parser.failures_from_persistence_file.map do |failure_hash|
      failure_hash.merge({
        example_name: name_map[failure_hash[:example_id]],
        time: flake_time
      })
    end
  end
end