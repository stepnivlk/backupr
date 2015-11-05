require 'spec_helper'
require 'yaml'

describe Backupr do
  before :all do
    options = { config_path: File.dirname(__FILE__) + '/fixtures/config.yml' }
    @backupr = Backupr.new(options)
    @config = YAML.load_file(options[:config_path])
  end

  describe "#config_exists?" do
    it "Checks if config file from given path exists and returns true" do
      expect(@backupr.config_exists?).to eql(true)
    end

    it "Checks non-existing config file and exits" do
      wrong_options = { config_path: "/wrong/path/config.yml"}
      wrong = Backupr.new(wrong_options)
      expect { wrong.config_exists? }.to raise_error(SystemExit)
    end
  end

  describe "#load_config" do
    it "Loads and checks config." do
      expect(@backupr.load_config).to eql(true)
    end
  end

  it 'has a version number' do
    expect(BackuprVersion::VERSION).not_to be nil
  end

end
