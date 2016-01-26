require 'yaml'

class FailureFormatter
  ID_TO_NAME_MAP_FILE = 'tmp/rspec_id_to_name_map.yml'
  RSpec::Core::Formatters.register FailureFormatter, :example_failed, :dump_failures

  def initialize(output)
    if File.exists?(ID_TO_NAME_MAP_FILE)
      @map = YAML.load(File.read(ID_TO_NAME_MAP_FILE))
    else
      @map = {}
    end
  end

  def example_failed(example)
    @map[example.example.id] = example.description
  end

  def dump_failures(examples)
    File.write(ID_TO_NAME_MAP_FILE, YAML.dump(@map))
  end
end

RSpec.configure do |config|
  config.example_status_persistence_file_path = 'tmp/rspec_examples.txt'
  config.add_formatter(RSpec::Core::Formatters::ProgressFormatter)
  config.add_formatter(FailureFormatter)
end