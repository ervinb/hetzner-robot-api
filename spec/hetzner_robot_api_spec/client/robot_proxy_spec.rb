require "spec_helper"
require "hetzner_robot_api/client"

describe HetznerRobotApi::Client::RobotProxy do
  describe "#append" do
    context "without query parameters" do
      before do
        @proxy = described_class.new
        @proxy.append("user")
      end

      it "accumulates keys (URL parts)" do
        expect(@proxy.keys).to include("user")
      end

      it "doesn't have additional query options" do
        expect(@proxy.options).to be_empty
      end
    end

    context "with query parameters" do
      before do
        @proxy = described_class.new
        @proxy.append("user", {:id => 5})
      end

      it "has additional query parameters" do
        expect(@proxy.options).to eq({:id => 5})
      end
    end
  end

  describe "#url" do
    before do
      @proxy = described_class.new
      @proxy.append("server")
      @proxy.append("1_2_3_4")
    end

    it "generates the correct URL" do
      expect(@proxy.url).to eq("https://robot-ws.your-server.de/server/1.2.3.4")
    end
  end
end
