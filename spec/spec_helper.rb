$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)

require "webmock/rspec"
require "hetzner_robot_api"
require "factory_girl"

WebMock.disable_net_connect!(allow_localhost: true)

RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods

  config.before(:suite) do
    FactoryGirl.find_definitions
  end
end
