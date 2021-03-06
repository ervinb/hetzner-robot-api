require "httparty"

require "hetzner_robot_api/client/robot_proxy"
require "hetzner_robot_api/client/robot_response"

module HetznerRobotApi
  class Client
    include HTTParty

    ROBOT_URL = "https://robot-ws.your-server.de"

    base_uri ROBOT_URL

    format :json

    def initialize(username, password)
      @auth = {
        :username => username,
        :password => password
      }

      @proxy = RobotProxy.new

      self.class.default_options.merge!({ :basic_auth => @auth })
    end

    def method_missing(http_method, *args, &block)
      @proxy.append(http_method, args[0])

      @options = { :query => @proxy.options }

      if args.size > 0 && !http_method.to_s == "post"
        execute("get")
      elsif http_method.to_s.match /\bget\b|\bpost\b/
        execute(http_method)
      else
        return self
      end
    end

    def execute(method)
      # TODO: handle connection issues
      puts "[#{method.upcase} #{@proxy.url} #{@options.to_s}]"

      http_response = self.class.send(method, @proxy.url, @options)

      robot_response = RobotResponse.construct(http_response)

      robot_response
    ensure
      @proxy = RobotProxy.new
    end
  end
end
