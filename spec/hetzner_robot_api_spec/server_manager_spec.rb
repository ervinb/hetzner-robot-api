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

  describe "#fetch_server_list" do
    before do
      allow(client).to receive_message_chain(:server, :get) { servers }
    end

    context "no filters provided" do
      it "lists all servers" do
        subject.fetch_server_list

        expect(subject.server_list).to eq(servers)
      end
    end

    context "filter is provided" do
      it "returns only a server with specific name" do
        subject.fetch_server_list(:filters => { :server_name => server_d10_1.server.server_name})

        expect(subject.server_list).to contain_exactly(server_d10_1)
      end

      it "returns only servers from DC10" do
        subject.fetch_server_list(:filters => { :dc => "10" })

        expect(subject.server_list).to eq([server_d10_1, server_d10_2])
      end

      it "handles ? matcher" do
        subject.fetch_server_list(:filters => { :server_name => "d10_?" })

        expect(subject.server_list).to eq([server_d10_1, server_d10_2])
      end

      it "handles * matcher" do
        subject.fetch_server_list(:filters => { :server_name => "d*" })

        expect(subject.server_list).to eq([server_d10_1, server_d10_2, server_d20_1])
      end
    end
  end

  describe "#print_server_table" do
    before do
      subject.instance_variable_set(:@server_list, servers)
    end

    it "prints a table with the servers" do
      fields = [:server_name, :server_ip]
      server_names = servers.map{|entry| entry.server.server_name}.join("|")
      output = /#{server_names}/

      expect{ subject.print_server_table(fields) }.to output(output).to_stdout
    end

    it "throws an exception if an invalid field is provided" do
      fields = [:server_name, :server_not_existing_field]

      expect { subject.print_server_table(fields) }.to raise_error(ArgumentError)
    end
  end

  describe "#server_list_to_format" do
    before do
      subject.instance_variable_set(:@server_list, servers)
    end

    it "outpus a YAML format by default" do
      expect( YAML.parse(subject.server_list_to_format).any? ).to be_truthy
    end

    it "outputs JSON format" do
      expect( JSON.parse(subject.server_list_to_format(:format => :json)).any? ).to be_truthy
    end

    it "outputs a simple list" do
      # "1.2.3.1\n1.2.3.2\n1.2.3.3"
      output = servers.map{|entry| entry.server.server_ip}.join("\n")

      expect( subject.server_list_to_format(:format => :list) ).to eq(output)
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
          ip_address = convert_ip_to_sym(entry.server.server_ip)

          allow(client.server).to receive_message_chain("#{ip_address}.post")

          expect(client.server).to receive_message_chain("#{ip_address}.post")
        end

        subject.update_server_names(@options)
      end
    end
  end

  describe "cancel_servers" do
    before do
      @earliest_cancellation_date = Time.now.to_date.to_s
      @fake_response = double("RobotResponse").as_null_object

      subject.instance_variable_set(:@server_list, servers)
    end

    context "servers are not yet cancelled" do
      it "cancels the servers in the list" do
        servers.each do |entry|
          ip_address = convert_ip_to_sym(entry.server.server_ip)

          allow(@fake_response).to receive_message_chain("cancellation.cancelled") { false }
          allow(client).to receive_message_chain("server.#{ip_address}.cancellation.get") { @fake_response }
          allow(@fake_response).to receive_message_chain("cancellation.earliest_cancellation_date") { @earliest_cancellation_date }

          expect(client).to receive_message_chain("server.#{ip_address}.cancellation.post").with({:cancellation_date => @earliest_cancellation_date})
        end

        subject.cancel_servers
      end
    end

    context "servers are already cancelled" do
      it "doesn't cancel the servers in the list" do
        servers.each do |entry|
          ip_address = convert_ip_to_sym(entry.server.server_ip)

          allow(@fake_response).to receive_message_chain("cancellation.cancelled") { true }
          allow(client).to receive_message_chain("server.#{ip_address}.cancellation.get") { @fake_response }
          allow(@fake_response).to receive_message_chain("cancellation.earliest_cancellation_date") { @earliest_cancellation_date }

          expect(client).to receive("server")
        end

        subject.cancel_servers
      end
    end
  end

  def convert_ip_to_sym(ip)
     ip.gsub(/\./, "_").to_sym
  end
end
