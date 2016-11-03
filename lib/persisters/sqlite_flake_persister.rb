class SqliteFlakePersister
  def initialize(db_file_name = 'tmp/test_flakes.sqlite3')
    @db = SQLite3::Database.new(db_file_name)
    @db.results_as_hash = true

    create_schema
  end

  attr_reader :db

  def persist_flake(flake_spec)
    db.execute(
      "INSERT INTO test_flakes (example_id, example_name, flaked_on, finished_on) VALUES (?, ?, ?, STRFTIME('%s', 'now'))",
      [flake_spec[:example_id], flake_spec[:example_name], flake_spec[:time].to_i]
    )
  end

  def flakes_since(time)
    db.execute(
      "SELECT * FROM test_flakes WHERE finished_on > ? AND finished_on < ?",
      time, Time.now.to_i
    )
  end

  private

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