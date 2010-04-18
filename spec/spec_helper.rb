ENV["RACK_ENV"] = "test"
THIRTY_DAYS = 2592000
FORTY_EIGHT_HOURS = 172800

require File.join(File.dirname(__FILE__), '..', 'usage.rb')

require 'rack/test'
require 'spec'
require 'spec/autorun'
require 'spec/interop/test'

Spec::Runner.configure do |conf|
  conf.include Rack::Test::Methods
end

def app; Sinatra::Application; end
