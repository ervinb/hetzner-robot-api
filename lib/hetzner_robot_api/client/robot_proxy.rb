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

        # convert 1_2_3_4 > 1.2.3.4
        key.gsub!(/_/, ".") if key =~ /^(\d{1,3}_){3}\d{1,3}$/

        @keys << key
      end

      def url
        @url = "#{ROBOT_URL}/" + @keys.join("/").gsub(/_/, '-')
      end
    end
  end
end
