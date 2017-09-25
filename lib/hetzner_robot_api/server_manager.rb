require "terminal-table"

module HetznerRobotApi
  class ServerManager

    class ServerTypeMismatchInList < StandardError; end
    class DuplicateServerName < StandardError; end

    attr_reader :server_list

    def initialize(client)
      @client = client
    end

    # Returns a list of available servers
    ## Filters enable listing only servers containing specific field values:
    ## :filters => { :server_name => "s1" } : will only return server S1
    ## :filters => { :dc => "10" } : will return all servers from DC10
    ## Supports wildcards ? (a single character) and * (any character(s))
    ## or regular expressions
    def fetch_server_list(options = {})
      defaults = {
        :filters => {}
      }

      @options = defaults.merge!(options)

      remote_servers = @client.server.get

      @server_list = apply_filters(remote_servers)
    end

    # Outputs a formatted table, containing all the servers
    # with their fields. By default, all fields are
    # shown. To show only some fields, pass an array
    # of field names (as symbols).
    def print_server_table(fields = [])
      all_fields   = @server_list.first.server.to_h.keys
      all_headings = all_fields.map{ |f| f.to_s }
      headings     = []

      table_rows = @server_list.map do |entry|
        row_data = []

        if fields.empty?
          headings = all_headings

          all_fields.each{ |field| row_data << entry.server.send(field) }
        else
          headings = fields.map{ |f| f.to_s }
          invalid_headings = headings - all_headings

          raise ArgumentError.new("Field(s) #{invalid_headings} don't exist!") if invalid_headings.length > 0

          fields.each{ |field| row_data << entry.server.send(field.to_sym) }
        end

        row_data
      end

      table = Terminal::Table.new(
        :headings => headings,
        :rows     => table_rows,
        :style    => {
          :border_y => "",
          :border_i => ""
        }
      )

      puts table
    end

    # Converts the servers to a certain format. Each server is
    # represented with its name and additional fields.
    #
    # Input parameters:
    #   :format => :sym
    #   :fields => []
    #
    # By default there's one additional field defined, :server_ip, and
    # :yaml is the default format.
    #
    # Supported formats are:
    # - :yaml
    #   The servers are converted to YAML, in the format:
    #
    #   servers:
    #     - server1:
    #         field1: value
    #         field2: value
    #
    # - :json
    #   The servers are converted to JSON, in the format:
    #
    #   {"servers":[{"server1":{"field1":"value", "field2":"value"}}, ...]}
    #
    # - :list
    #   The servers are converted to a simple list, consisting only
    #   of the first field's value:
    #
    #   1.2.3.4
    #   1.2.3.5
    #
    def server_list_to_format(options = {})
      defaults = {
        :format => :yaml,
        :fields => [ :server_ip ]
      }

      options = defaults.merge!(options)

      servers_hash = { "servers" => convert_servers_to_hashes(options[:fields]) }

      case options[:format]
      when :json
        servers_hash.to_json
      when :yaml
        servers_hash.to_yaml
      when :list
        field = options[:fields].first

        servers_hash["servers"].map{|entry| entry.values.first[field.to_s]}.join("\n")
      end
    end

    # Updates the server names with a format: "<prefix><start_number(+1)>"
    def update_server_names(options)
      defaults = {
        :prefix       => "",
        :start_number => nil
      }

      options = defaults.merge!(options)

      raise ArgumentError.new("Options can't contain empty values!") if options.any? { |_, opt_v| opt_v.nil? || opt_v.to_s.empty? }

      raise ServerTypeMismatchInList unless servers_same_type?

      prefix         = options[:prefix]
      postfix        = options[:start_number]
      remote_servers = @client.server.get

      @server_list.each do |entry|
        ip_address   = convert_ip_to_sym(entry.server.server_ip)
        current_name = entry.server.server_name
        new_name     = "#{prefix}#{postfix}"

        raise DuplicateServerName.new("#{new_name} already exists!") if remote_servers.any? {|entry| entry.server.server_name == new_name}

        # TODO: logger, move to future Server class
        @client.server.send(ip_address).post(:server_name => new_name)

        postfix = postfix.next
      end
    end

    # Cancells all the servers in the list. By default, the cancellation
    # date is set to the earliest possible, but it can be modified with the
    # date option.
    #
    # eg. cancel_servers(:cancellation_date => '2017-03-14')
    #
    def cancel_servers(options = {})
      defaults = {
        :cancellation_date => nil
      }

      options = defaults.merge(options)

      date_format = "%Y-%m-%d"

      @server_list.each do |entry|
        ip_address = convert_ip_to_sym(entry.server.server_ip)

        cancellation_info = @client.server.send(ip_address).cancellation.get
        earliest_cancellation = cancellation_info.cancellation.earliest_cancellation_date

        earliest_cancellation_date = Date.strptime(earliest_cancellation, date_format)
        requested_date = if options[:date].nil?
                           Time.now.to_date
                         else
                           Date.strptime(options[:date], date_format)
                         end

        cancellation_date = requested_date > earliest_cancellation_date ? requested_date : earliest_cancellation_date

        if cancellation_info.cancellation.cancelled
          puts "#{entry.server.server_name}: already cancelled, skipping ..."
        else
          cancellation_request = @client.server.send(ip_address).cancellation.post(:cancellation_date => cancellation_date.to_s)

          puts "#{entry.server.server_name}: #{cancellation_request}"
        end
      end
    end

    private

    def apply_filters(server_list)
      server_list.select do |entry|
        @options[:filters].all? do |field, value|
          value_regex = value
                          .gsub(/\?/, ".")
                          .gsub(/\*/, ".*")

          entry.server.send(field.to_sym) =~ /^#{value_regex}$/
        end
      end
    end

    # convert 1.2.3.4 > 1_2_3_4 so that it can be sent as a method to the client
    # TODO: to helper module
    def convert_ip_to_sym(ip)
       ip.gsub(/\./, "_").to_sym
    end

    def servers_same_type?
      product = @server_list.first.server.product

      @server_list.all? {|entry| entry.server.product == product}
    end

    # TODO: to_h in future Server class
    def convert_servers_to_hashes(fields)
      result = []

      @server_list.each do |entry|
        server_hash = entry.server.to_h
        server_name = entry.server.server_name
        new_hash = { server_name => {} }

        server_hash = server_hash.tap{ |sh| sh.delete(:server_name) }

        fields.each{ |field| new_hash[server_name][field.to_s] = server_hash[field] }

        result << new_hash
      end

      result
    end

  end
end
