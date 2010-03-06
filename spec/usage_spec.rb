require File.dirname(__FILE__) + '/spec_helper'

describe "mediawiki-usage" do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  it "should respond to /" do
    get '/'
    last_response.should be_ok
  end
  
  it "should return API documentation" do
    get '/'
    last_response.body.should =~ /API Documentation/
  end
end