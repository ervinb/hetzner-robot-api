require "byebug"
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

        key_string = key.to_s

        # don't append GET and POST
        return if key_string.match(/\bget\b|\bpost\b/)

        # convert 1_2_3_4 > 1.2.3.4
        key_string.gsub!(/_/, ".") if key_string =~ /^(\d{1,3}_){3}\d{1,3}$/

        @keys << key_string
      end

      def url
        @url = "#{ROBOT_URL}/" + @keys.join("/").gsub(/_/, '-')
      end
    end
  end
end
