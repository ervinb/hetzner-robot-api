module HetznerRobotApi
  class Client
    class RobotResponse
      attr_reader :errors

      def initialize(hash)
        hash.each do |key, value|
          value = RobotResponse.new(value) if value.class == Hash

          self.instance_variable_set("@#{key}", value)
          self.class.send(:define_method, key, proc{ self.instance_variable_get("@#{key}") })
        end
      end

      def self.construct(response)
        parsed_response = JSON.parse(response.body)

        if parsed_response.class == Array
          parsed_response.collect{|item| RobotResponse.new(item)}
        else
          RobotResponse.new(parsed_response)
        end
      end
    end
  end
end
