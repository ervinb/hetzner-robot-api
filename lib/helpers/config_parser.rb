require "psych"

module Helpers
  class ConfigParser
    attr_reader :path

    def initialize(path)
        @path = path
        @config = Psych.load_file(path)
    rescue Exception => ex
        puts "Config file missing: #{path}"

        raise ex
    end

    def get(key)
      if @config.has_key?(key)
        @config[key]
      else
        puts "#{key} is not defined in the config file!"

        nil
      end
    end
  end
end
