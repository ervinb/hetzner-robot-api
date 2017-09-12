require "terminal-table"

module HetznerRobotApi
  class ServerManager

    class ServerTypeMismatchInList < StandardError; end
    class DuplicateServerName < StandardError; end

    def initialize(client)
      @client = client
    end

    # Returns a list of available servers
    ## Filters enable listing only servers containing specific field values:
    ## :filters => { :server_name => "s1" } : will only return server S1
    ## :filters => { :dc => "10" } : will return all servers from DC10
    ## Supports wildcards ? (a single character) and * (any character(s))
    ## or regular expressions
    def server_list(options = {})
      defaults = {
        :filters => {}
      }

      @options = defaults.merge!(options)

      @servers ||= @client.server.get

      apply_filters
    end

    def self.print_formatted_server_list(server_list, fields = [])
      # TODO: handle empty fields > print all
      table_rows = server_list.map do |entry|
        row_data = []

        # TODO: handle missing fields
        fields.each{ |field| row_data << entry.server.send(field.to_sym) }

        row_data
      end

      table = Terminal::Table.new(:rows => table_rows)

      puts table
    end

    # Updates the server names with a format: "<prefix><start_number++>"
    def update_server_names(server_list, options)
      defaults = {
        :prefix => "",
        :start_number => nil
      }

      options = defaults.merge!(options)

      raise ArgumentError.new("Options can't contain empty values!") if options.any? { |_, opt_v| opt_v.nil? || opt_v.to_s.empty? }

      raise ServerTypeMismatchInList unless servers_same_type?(server_list)

      # get last server matching the prefix and continue from that number?
      prefix = options[:prefix]
      postfix = options[:start_number]

      remote_servers = @client.server.get

      server_list.each do |entry|
        ip_address = entry.server.server_ip
        current_name = entry.server.server_name
        new_name = "#{prefix}#{postfix}"

        raise DuplicateServerName.new("#{new_name} already exists!") if remote_servers.any? {|entry| entry.server.server_name == new_name}

        # TODO: logger
        @client.server.post(:server_name => new_name)

        postfix = postfix.next
      end
    end

    private

    def apply_filters
      @servers.select do |entry|
        @options[:filters].all? do |field, value|
          value_regex = value
                          .gsub(/\?/, ".")
                          .gsub(/\*/, ".*")

          entry.server.send(field.to_sym) =~ /^#{value_regex}$/
        end
      end
    end

    def servers_same_type?(server_list)
      product = server_list.first.server.product

      server_list.all? {|entry| entry.server.product == product}
    end

  end
end
