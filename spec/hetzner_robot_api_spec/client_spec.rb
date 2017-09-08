require "spec_helper"
require "hetzner_robot_api/client"

describe HetznerRobotApi::Client do
  describe "#execute" do
    before do
      @client = described_class.new("user", "pass")

      stub_request(:get, "https://robot-ws.your-server.de/server").to_return(status: 200, body: "", headers: {})

      allow(HetznerRobotApi::Client::RobotResponse).to receive(:construct) { HetznerRobotApi::Client::RobotResponse.new }
      allow(HetznerRobotApi::Client::RobotProxy).to receive(:new) { double(HetznerRobotApi::Client::RobotProxy) }
    end

    it "returns a RobotResponse" do
      expect(@client.server.get).to be_a(HetznerRobotApi::Client::RobotResponse)
    end
  end
end
