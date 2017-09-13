# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'hetzner_robot_api/version'

Gem::Specification.new do |spec|
  spec.name          = "hetzner_robot_api"
  spec.version       = HetznerRobotApi::VERSION
  spec.authors       = ["Ervin Barta"]
  spec.email         = ["ervin@renderedtext.com"]

  spec.summary       = %q{Wrapper for Hetzner Webservice}
  spec.description   = %q{Convenience methods for accessing Hetzner's Webservice}
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.13"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "webmock", "~> 3.0"
  spec.add_development_dependency "factory_girl", "~> 4.0"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "byebug"

  spec.add_dependency "httparty"
  spec.add_dependency "json"
  spec.add_dependency "terminal-table"
end
