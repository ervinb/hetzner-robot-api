require "spec_helper"
require "hetzner_robot_api/client"

describe HetznerRobotApi::Client::RobotResponse do
  let(:response) {
    [
      {
        "server"=> {
          "server_ip"=>"144.76.28.80",
          "ids" => [
            "nested" => "field"
          ]
        },
        "owner" => "rt"
      }
    ].to_json
  }
  describe "construct" do
    before do
      allow(response).to receive(:body) { response }

      @constructed_response = described_class.construct(response)
    end

    it "creates an OpeStruct datastructure" do
      expect(@constructed_response.server).to be_a(OpenStruct)
    end

    it "fields are accessible through methods (chain)" do
      expect(@constructed_response.server.server_ip).to eq("144.76.28.80")
    end
  end
end
