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

  describe "#create_server_list" do
    before do
      allow(client).to receive_message_chain(:server, :get) { servers }
    end

    context "no filters provided" do
      it "lists all servers" do
        subject.create_server_list

        expect(subject.server_list).to eq(servers)
      end
    end

    context "filter is provided" do
      it "returns only a server with specific name" do
        subject.create_server_list(:filters => { :server_name => server_d10_1.server.server_name})

        expect(subject.server_list).to contain_exactly(server_d10_1)
      end

      it "returns only servers from DC10" do
        subject.create_server_list(:filters => { :dc => "10" })

        expect(subject.server_list).to eq([server_d10_1, server_d10_2])
      end

      it "handles ? matcher" do
        subject.create_server_list(:filters => { :server_name => "d10_?" })

        expect(subject.server_list).to eq([server_d10_1, server_d10_2])
      end

      it "handles * matcher" do
        subject.create_server_list(:filters => { :server_name => "d*" })

        expect(subject.server_list).to eq([server_d10_1, server_d10_2, server_d20_1])
      end
    end
  end

  describe "#print_formatted_server_list" do
    before do
      subject.instance_variable_set(:@server_list, servers)
    end

    it "prints a table with the servers" do
      fields = [:server_name, :server_ip]
      server_names = servers.map{|entry| entry.server.server_name}.join("|")
      output = /#{server_names}/

      expect{ subject.print_formatted_server_list(fields) }.to output(output).to_stdout
    end

    it "throws an exception if an invalid field is provided" do
      fields = [:server_name, :server_not_existing_field]

      expect { subject.print_formatted_server_list(fields) }.to raise_error(ArgumentError)
    end
  end

  describe "#update_server_names" do
    before do
      @options = { :prefix => "s", :start_number => 1}

      allow(client).to receive_message_chain(:server, :get) { servers }
      allow(client).to receive_message_chain(:server, :post)

      subject.instance_variable_set(:@server_list, servers)
    end

    it "raises an exception when insufficient options are provided" do
        expect{ subject.update_server_names({:prefix => "s", :start_number => nil}) }.to raise_error(ArgumentError)
    end

    context "server types differ in the list" do
      before do
        allow(server_d10_2).to receive_message_chain(:server, :product) { "PX1" }
      end

      it "raises a ServerTypeMismatchInList exception" do
        expect{ subject.update_server_names(@options) }.to raise_error(HetznerRobotApi::ServerManager::ServerTypeMismatchInList)
      end
    end

    context "options are valid and there's a name conflict" do
      it "raises a DuplicateServerName exception" do
        expect{ subject.update_server_names({:prefix => "d10_", :start_number => 1}) }.to raise_error(HetznerRobotApi::ServerManager::DuplicateServerName)
      end
    end

    context "options are valid and there is no name conflict" do
      it "updates the server names" do
        servers.each do |entry|
          ip_address = entry.server.server_ip.gsub(/\./, "_")
          allow(client.server).to receive_message_chain("#{ip_address}.post")

          expect(client.server).to receive_message_chain("#{ip_address}.post")
        end

        subject.update_server_names(@options)
      end
    end
  end
end
