require 'spec_helper'
require 'yaml'

class Counter
  COUNTS_FILE = 'tmp/rspec_run_count'
  attr_reader :count

  def initialize
    if File.exists?(COUNTS_FILE)
      @count = File.read(COUNTS_FILE).to_i
    else
      @count = 1
    end
  end

  def increment
    @count += 1
    File.write(COUNTS_FILE, @count)
  end
end

$run_counts = Counter.new

RSpec.describe "flaky spec" do
  before do
    sleep 1
  end

  after(:all) do
    $run_counts.increment
  end

  it "flakes exactly two times" do
    expect($run_counts.count).to be > 2
  end

  it "flakes exactly two times also" do
    expect($run_counts.count).to be > 2
  end

  describe 'within this nested block' do
    it "flakes exactly once" do
      expect($run_counts.count).to be > 1
    end

    it "does not flake" do
      expect(1).to eq(1)
    end
  end
end