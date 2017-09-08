$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)

require "webmock/rspec"
require "hetzner_robot_api"

WebMock.disable_net_connect!(allow_localhost: true)
