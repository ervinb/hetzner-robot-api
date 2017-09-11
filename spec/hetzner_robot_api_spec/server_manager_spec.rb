require "byebug"
require "spec_helper"
require "hetzner_robot_api/server_manager"

describe HetznerRobotApi::ServerManager do

  let(:server_d10_1) { build(:server, :server_name => "d10_1") }
  let(:server_d10_2) { build(:server, :server_name => "d10_2") }
  let(:server_d20_1) { build(:server, :server_name => "d20_1", :dc => "20") }

  let(:servers) { [server_d10_1, server_d10_2, server_d20_1] }

  let(:client)  { double(HetznerRobotApi::Client) }

  subject { described_class.new(client) }

  describe "#server_list" do
    before do
      client.stub_chain(:server, :get) { servers }
    end

    context "no filters provided" do
      it "lists all servers" do
        expect(subject.server_list).to eq(servers)
      end
    end

    context "filter is provided" do
      it "returns only a server with specific name" do
        expect(subject.server_list(
          :filters => { :server_name => server_d10_1.server.server_name }
        )).to contain_exactly(server_d10_1)
      end

      it "returns only servers from DC10" do
        expect(subject.server_list(:filters => { :dc => "10" })).to eq([server_d10_1, server_d10_2])
      end
    end
  end

  describe "print_formatted_server_list" do
    it "prints a table with the servers" do
      server = server_d10_1.server

      expect{ described_class.print_formatted_server_list(servers, [:server_name, :server_ip]) }.to output(/#{server.server_name} \| #{server.server_ip}/).to_stdout
    end
  end
end
