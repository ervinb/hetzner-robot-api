module HetznerRobotApi
  class Client
    class RobotResponse
      attr_reader :errors

      def self.construct(response)
        parsed_response = JSON.parse(response.body, :object_class => OpenStruct)

       parsed_response.length == 1 ? parsed_response.first : parsed_response
      rescue JSON::ParserError, TypeError => e
        puts "Not a string, or not a valid JSON"
        puts "Response: #{response}"

        raise e
      end
    end
  end
end
