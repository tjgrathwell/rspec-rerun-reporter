require 'yaml'
require_relative 'failure_file_parser'

class RspecRerunner
  RERUN_ATTEMPTS = ENV.fetch('RERUN_ATTEMPTS', 5).to_i
  RERUN_THRESHOLD = ENV.fetch('RERUN_THRESHOLD', 5).to_i

  def initialize
    @flake_reporter = FlakeReporter.new
    @failure_file_parser = FailureFileParser.new('tmp/rspec_examples.txt')
  end

  def run_tests
    succeeded_initially = system("bundle exec rspec spec")
    return if succeeded_initially

    failure_count = @failure_file_parser.failures_from_persistence_file.length
    if failure_count > RERUN_THRESHOLD
      puts "#{failure_count} tests failed, first run, which is over the rerun threshold of #{RERUN_THRESHOLD}"
      exit 1
    end

    @flake_reporter.add_flakes_from_persistance_file

    RERUN_ATTEMPTS.times do
      succeeded_on_retry = system("bundle exec rspec spec --only-failures")
      if succeeded_on_retry
        @flake_reporter.persist_flakes
        return
      else
        @flake_reporter.add_flakes_from_persistance_file
      end
    end

    puts "TESTS HAVE FAILED AFTER #{RERUN_ATTEMPTS} RETRIES!"
    exit 1
  end
end