require "helpers/config_parser"

describe Helpers::ConfigParser do

  let(:config_parser) { described_class.new("fixtures/hetzner-credentials.yml") }

  it "raises an exception when the config path is missing" do
    expect{described_class.new("fixtures/missing.yml")}.to raise_error(Exception, /missing/)

  end

  describe "#get" do
    it "returns the username" do
      expect(config_parser.get("username")).to eq("robot-user")
    end

    it "returns nil for non-existing fields" do
      expect(config_parser.get("url")).to be_nil
    end
  end
end
