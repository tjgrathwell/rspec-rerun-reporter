require 'yaml'

class RspecRerunner
  RERUN_ATTEMPTS = 5

  def initialize
    @flake_reporter = FlakeReporter.new
  end

  def run_tests
    succeeded_initially = system("bundle exec rspec spec")
    return if succeeded_initially

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