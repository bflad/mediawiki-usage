require File.dirname(__FILE__) + '/spec_helper'

describe "mediawiki-usage GET /" do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  it "should be successful" do
    get '/'
    last_response.should be_ok
  end
end

describe "mediawiki-usage GET /docs" do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  it "should be successful" do
    get '/docs'
    last_response.should be_ok
  end
  
  it "should respond with API documentation" do
    get '/docs'
    last_response.body.should =~ /API Documentation/
  end
end

describe "mediawiki-usage GET /count" do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end
  
  before do
    @thirty_days = 2592000
    @params = {
      :start => Time.now.to_i,
      :end => (Time.now + @thirty_days).to_i
    }
  end
  
  it "should be unsuccessful without range parameters" do
    get '/count'
    last_response.status.should == 400
  end

  it "should be unsuccessful with range parameters spanning over 30 days" do
    get '/count', @params.merge!(:end => @params[:end] + 1)
    last_response.status.should == 413
  end
  
  it "should be successful with range parameters" do
    DataMapper.stub!(:setup).and_return(true)
    DataMapper.repository(:default).adapter.stub!(:select).and_return([ ])
    
    get '/count', @params
    last_response.body.should == "{\"changes\":0}"
  end
  
  it "should be successful with callback parameter" do
    DataMapper.stub!(:setup).and_return(true)
    DataMapper.repository(:default).adapter.stub!(:select).and_return([ ])
    
    get '/count', @params.merge!(:callback => "test")
    last_response.body.should == "test({\"changes\":0})"
  end
end

describe "mediawiki-usage GET /count/hour" do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  before do
    @thirty_days = 2592000
    @params = {
      :start => Time.now.to_i,
      :end => (Time.now + @thirty_days).to_i
    }
  end

  it "should be unsuccessful without range parameters" do
    get '/count/hour'
    last_response.status.should == 400
  end

  it "should be unsuccessful with range parameters spanning over 30 days" do
    get '/count/hour', @params.merge!(:end => @params[:end] + 1)
    last_response.status.should == 413
  end

  it "should be successful with range parameters" do
    DataMapper.stub!(:setup).and_return(true)
    DataMapper.repository(:default).adapter.stub!(:select).and_return([ ])

    get '/count/hour', @params
    last_response.body.should == "[]"
  end

  it "should be successful with callback parameter" do
    DataMapper.stub!(:setup).and_return(true)
    DataMapper.repository(:default).adapter.stub!(:select).and_return([ ])

    get '/count/hour', @params.merge!(:callback => "test")
    last_response.body.should == "test([])"
  end
end

describe "mediawiki-usage GET /count/day" do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  before do
    @thirty_days = 2592000
    @params = {
      :start => Time.now.to_i,
      :end => (Time.now + @thirty_days).to_i
    }
  end

  it "should be unsuccessful without range parameters" do
    get '/count/day'
    last_response.status.should == 400
  end

  it "should be unsuccessful with range parameters spanning over 30 days" do
    get '/count/day', @params.merge!(:end => @params[:end] + 1)
    last_response.status.should == 413
  end

  it "should be successful with range parameters" do
    DataMapper.stub!(:setup).and_return(true)
    DataMapper.repository(:default).adapter.stub!(:select).and_return([ ])

    get '/count/day', @params
    last_response.body.should == "[]"
  end

  it "should be successful with callback parameter" do
    DataMapper.stub!(:setup).and_return(true)
    DataMapper.repository(:default).adapter.stub!(:select).and_return([ ])

    get '/count/day', @params.merge!(:callback => "test")
    last_response.body.should == "test([])"
  end
end

describe "mediawiki-usage GET /editors" do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end
  
  before do
    @thirty_days = 2592000
    @params = {
      :start => Time.now.to_i,
      :end => (Time.now + @thirty_days).to_i
    }
  end
  
  it "should be unsuccessful without range parameters" do
    get '/editors'
    last_response.status.should == 400
  end
  
  it "should be unsuccessful with range parameters spanning over 30 days" do
    get '/editors', @params.merge!(:end => @params[:end] + 1)
    last_response.status.should == 413
  end
  
  it "should be successful with range parameters" do
    DataMapper.stub!(:setup).and_return(true)
    DataMapper.repository(:default).adapter.stub!(:select).and_return([ ])
    
    get '/editors', @params
    last_response.body.should == "[]"
  end
  
  it "should be successful with callback parameter" do
    DataMapper.stub!(:setup).and_return(true)
    DataMapper.repository(:default).adapter.stub!(:select).and_return([ ])
    
    get '/editors', @params.merge!(:callback => "test")
    last_response.body.should == "test([])"
  end
end

describe "mediawiki-usage GET /pages" do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end
 
  before do
    @thirty_days = 2592000
    @params = {
      :start => Time.now.to_i,
      :end => (Time.now + @thirty_days).to_i
    }
  end
  
  it "should be unsuccessful without range parameters" do
      get '/pages'
      last_response.status.should == 400
  end

  it "should be unsuccessful with range parameters spanning over 30 days" do
    get '/pages', @params.merge!(:end => @params[:end] + 1)
    last_response.status.should == 413
  end

  it "should be successful with range parameters" do
    DataMapper.stub!(:setup).and_return(true)
    DataMapper.repository(:default).adapter.stub!(:select).and_return([ ])
    
    get '/pages', @params
    last_response.body.should == "[]"
  end
  
  it "should be successful with callback parameter" do
    DataMapper.stub!(:setup).and_return(true)
    DataMapper.repository(:default).adapter.stub!(:select).and_return([ ])
    
    get '/pages', @params.merge!(:callback => "test")
    last_response.body.should == "test([])"
  end
end
