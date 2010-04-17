require File.dirname(__FILE__) + '/spec_helper'

describe "mediawiki-usage GET /" do
  it "should be successful" do
    get '/'
    last_response.should be_ok
  end
end

describe "mediawiki-usage GET /docs" do
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
  before do
    CACHE = mock(Redis, :get => nil, :set => true, :expire => true)
    DB = mock(Mysql, :prepare => mock(Mysql::Stmt, :execute => [ "0" ]))
    CACHE_CONNECTED = true

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
    get '/count', @params
    last_response.body.should == "{\"count\":0}"
  end

  it "should be successful with callback parameter" do
    get '/count', @params.merge!(:callback => "test")
    last_response.body.should == "test({\"count\":0})"
  end
end

describe "mediawiki-usage GET /count/hour" do
  before do
    CACHE = mock(Redis, :get => nil, :set => true, :expire => true)
    DB = mock(Mysql, :prepare => mock(Mysql::Stmt, :execute => {"12" => "0"}))
    CACHE_CONNECTED = true

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
    get '/count/hour', @params
    last_response.body.should == "[{\"12\":0}]"
  end

  it "should be successful with callback parameter" do
    get '/count/hour', @params.merge!(:callback => "test")
    last_response.body.should == "test([{\"12\":0}])"
  end
end

describe "mediawiki-usage GET /count/day" do
  before do
    CACHE = mock(Redis, :get => nil, :set => true, :expire => true)
    DB = mock(Mysql, :prepare => mock(Mysql::Stmt, :execute => {"31" => "0"}))
    CACHE_CONNECTED = true

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
    get '/count/day', @params
    last_response.body.should == "[{\"31\":0}]"
  end

  it "should be successful with callback parameter" do
    get '/count/day', @params.merge!(:callback => "test")
    last_response.body.should == "test([{\"31\":0}])"
  end
end

describe "mediawiki-usage GET /editors" do
  before do
    CACHE = mock(Redis, :get => nil, :set => true, :expire => true)
    DB = mock(Mysql, :prepare => mock(Mysql::Stmt, :execute => {"Joker" => "0"}))
    CACHE_CONNECTED = true

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
    get '/editors', @params
    last_response.body.should == "[{\"Joker\":0}]"
  end

  it "should be successful with callback parameter" do
    get '/editors', @params.merge!(:callback => "test")
    last_response.body.should == "test([{\"Joker\":0}])"
  end
end

describe "mediawiki-usage GET /pages" do
  before do
    CACHE = mock(Redis, :get => nil, :set => true, :expire => true)
    DB = mock(Mysql, :prepare => mock(Mysql::Stmt, :execute => {"Joker" => "0"}))
    CACHE_CONNECTED = true

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
    get '/pages', @params
    last_response.body.should == "[{\"Joker\":0}]"
  end

  it "should be successful with callback parameter" do
    get '/pages', @params.merge!(:callback => "test")
    last_response.body.should == "test([{\"Joker\":0}])"
  end
end
