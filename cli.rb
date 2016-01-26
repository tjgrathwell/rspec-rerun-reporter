#!/usr/bin/env ruby

require 'thor'
require 'fileutils'
require_relative 'lib/flake_reporter'
require_relative 'lib/rspec_rerunner'

class RspecRerunnerCli < Thor
  desc "run_tests", "Run the tests with retries"
  def run_tests
    FileUtils.rm_f('tmp/rspec_run_count')

    RspecRerunner.new.run_tests
  end

  desc "report_flakes", "Report the frequency of flaky tests today"
  def report_flakes
    puts "#{'=' * 15} FLAKE REPORT #{'=' * 15}"
    FlakeReporter.new.report_flakes(:week)
    puts
    FlakeReporter.new.report_flakes(:day)
    puts "=" * 44
  end
end

RspecRerunnerCli.start(ARGV)
