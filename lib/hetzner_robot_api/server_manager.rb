module HetznerRobotApi
  class ServerManager

    def initialize(client)
      @client = client
    end

    # Lists all the available servers
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
