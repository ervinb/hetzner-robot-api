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
    def create_server_list(options = {})
      defaults = {
        :filters => {}
      }

      @options = defaults.merge!(options)

      remote_servers ||= @client.server.get

      @server_list = apply_filters(remote_servers)
    end

    def print_formatted_server_list(fields = [])
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
          :border_y => ""
        }
      )

      puts table
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
        ip_address   = entry.server.server_ip.gsub(/\./, "_")
        current_name = entry.server.server_name
        new_name     = "#{prefix}#{postfix}"

        raise DuplicateServerName.new("#{new_name} already exists!") if remote_servers.any? {|entry| entry.server.server_name == new_name}

        # TODO: logger, move to future Server class
        puts "Updating name #{current_name} -> #{new_name} [#{ip_address}]"
        @client.server.send(ip_address.to_sym).post(:server_name => new_name)

        postfix = postfix.next
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

    def servers_same_type?
      product = @server_list.first.server.product

      @server_list.all? {|entry| entry.server.product == product}
    end

  end
end
