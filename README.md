# rspec-rerun-reporter

This is a sample project demonstrating a way to retry tests using
RSpec 3's `--only-failures` option, while aggregating flaky tests
in a sqlite3 database so they can be reported on a daily/weekly/etc
basis.

## Usage

Run the tests (they will intentionally flake)

`./cli.rb run_tests`

Get a report of flaky tests

`./cli.rb report_flakes`