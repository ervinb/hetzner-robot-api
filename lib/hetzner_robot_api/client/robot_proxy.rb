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

        # handling IPs from 1_2_3_4 to 1.2.3.4
        key_string.gsub!(/_/, ".") if ip?(key_string)

        # handling order IDs B20150121_344958_251479 > B20150121-344958-251479
        key_string.gsub!(/_/, '-') if order_number?(key_string)

        @keys << key_string
      end

      def url
        @url = "#{ROBOT_URL}/" + @keys.join("/")
      end

      private

      def ip?(string)
        string =~ /^(\d{1,3}_){3}\d{1,3}$/
      end

      def order_number?(string)
        string =~ /^[a-zA-Z]{1}[\d+,_]+$/
      end
    end
  end
end
