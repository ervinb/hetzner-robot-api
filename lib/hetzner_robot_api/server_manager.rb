require "terminal-table"

module HetznerRobotApi
  class ServerManager

    def initialize(client)
      @client = client
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

    # Returns a list of available servers
    ## Filters enable listing only servers containing specific field values:
    ## :filters => { :server_name => "s1" } : will only return server S1
    ## :filters => { :dc => "10" } : will return all servers from DC10
    def server_list(options = {})
      defaults = {
        :filters => {}
      }

      @options = defaults.merge!(options)

      @servers ||= @client.server.get

      apply_filters
    end

    private

    # TODO: add option for regex matching
    def apply_filters
      @servers.select do |entry|
        @options[:filters].all? do |field, value|
          entry.server.send(field.to_sym) == value
        end
      end
    end

  end
end
