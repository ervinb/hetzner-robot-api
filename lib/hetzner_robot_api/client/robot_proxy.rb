module HetznerRobotApi
  class Client
    class RobotProxy
      attr_reader :keys, :options

      def initialize
        @keys = []
        @options = {}
      end

      def append(key, options = {})
        # store HTTP query parameters
        @options.merge!(options) if options

        @keys << key
      end

      def url
        @url = "#{ROBOT_URL}/" + @keys.join("/").gsub(/_/, '-')
      end
    end
  end
end
