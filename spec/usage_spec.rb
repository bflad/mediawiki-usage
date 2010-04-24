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

    @params = {
      :start => Time.now.to_i,
      :end => (Time.now + THIRTY_DAYS).to_i
    }
  end

  it "should be successful without range parameters" do
    get '/count.json'
    last_response.status.should == 200
  end

  it "should be unsuccessful with range parameters spanning over 30 days" do
    get '/count.json', @params.merge!(:end => @params[:end] + 1)
    last_response.status.should == 413
  end

  it "should be successful with range parameters" do
    get '/count.json', @params
    last_response.body.should == "{\"count\":0}"
  end

  it "should be successful with callback parameter" do
    get '/count.json', @params.merge!(:callback => "test")
    last_response.body.should == "test({\"count\":0})"
  end
end

describe "mediawiki-usage GET /count/hour" do
  before do
    CACHE = mock(Redis, :get => nil, :set => true, :expire => true)
    DB = mock(Mysql, :prepare => mock(Mysql::Stmt, :execute => {"12" => "0"}))
    CACHE_CONNECTED = true

    @params = {
      :start => Time.now.to_i,
      :end => (Time.now + THIRTY_DAYS).to_i
    }
  end

  it "should be successful without range parameters" do
    get '/count/hour.json'
    last_response.status.should == 200
  end

  it "should be unsuccessful with range parameters spanning over 30 days" do
    get '/count/hour.json', @params.merge!(:end => @params[:end] + 1)
    last_response.status.should == 413
  end

  it "should be successful with range parameters" do
    get '/count/hour.json', @params
    last_response.body.should == "[{\"12\":0}]"
  end

  it "should be successful with callback parameter" do
    get '/count/hour.json', @params.merge!(:callback => "test")
    last_response.body.should == "test([{\"12\":0}])"
  end
end

describe "mediawiki-usage GET /count/day" do
  before do
    CACHE = mock(Redis, :get => nil, :set => true, :expire => true)
    DB = mock(Mysql, :prepare => mock(Mysql::Stmt, :execute => {"31" => "0"}))
    CACHE_CONNECTED = true

    @params = {
      :start => Time.now.to_i,
      :end => (Time.now + THIRTY_DAYS).to_i
    }
  end

  it "should be successful without range parameters" do
    get '/count/day.json'
    last_response.status.should == 200
  end

  it "should be unsuccessful with range parameters spanning over 30 days" do
    get '/count/day.json', @params.merge!(:end => @params[:end] + 1)
    last_response.status.should == 413
  end

  it "should be successful with range parameters" do
    get '/count/day.json', @params
    last_response.body.should == "[{\"31\":0}]"
  end

  it "should be successful with callback parameter" do
    get '/count/day.json', @params.merge!(:callback => "test")
    last_response.body.should == "test([{\"31\":0}])"
  end
end

describe "mediawiki-usage GET /editors" do
  before do
    CACHE = mock(Redis, :get => nil, :set => true, :expire => true)
    DB = mock(Mysql, :prepare => mock(Mysql::Stmt, :execute => {"Joker" => "0"}))
    CACHE_CONNECTED = true

    @params = {
      :start => Time.now.to_i,
      :end => (Time.now + THIRTY_DAYS).to_i
    }
  end

  it "should be successful without range parameters" do
    get '/editors.json'
    last_response.status.should == 200
  end

  it "should be successful without range parameters and recent.png" do
    response = mock(Object, :read => "png")
    OpenURI.stub!(:open_uri => response)

    get '/editors.png'
    last_response.status.should == 200
  end

  it "should be unsuccessful with range parameters spanning over 30 days" do
    get '/editors.json', @params.merge!(:end => @params[:end] + 1)
    last_response.status.should == 413
  end

  it "should be unsuccessful with range parameters spanning over 30 days and recent.png" do
    response = mock(Object, :read => "png")
    OpenURI.stub!(:open_uri => response)

    get '/editors.png', @params.merge!(:end => @params[:end] + 1)
    last_response.status.should == 413
  end

  it "should be successful with range parameters" do
    get '/editors.json', @params
    last_response.body.should == "[{\"Joker\":0}]"
  end

  it "should be successful with range parameters and recent.png" do
    response = mock(Object, :read => "png")
    OpenURI.stub!(:open_uri => response)

    get '/editors.png', @params
    last_response.headers["Content-Type"] == "image/png"
  end

  it "should be successful with callback parameter" do
    get '/editors.json', @params.merge!(:callback => "test")
    last_response.body.should == "test([{\"Joker\":0}])"
  end
end

describe "mediawiki-usage GET /pages" do
  before do
    CACHE = mock(Redis, :get => nil, :set => true, :expire => true)
    DB = mock(Mysql, :prepare => mock(Mysql::Stmt, :execute => {"Joker" => "0"}))
    CACHE_CONNECTED = true

    @params = {
      :start => Time.now.to_i,
      :end => (Time.now + THIRTY_DAYS).to_i
    }
  end

  it "should be successful without range parameters" do
      get '/pages.json'
      last_response.status.should == 200
  end

  it "should be successful without range parameters and recent.png" do
    response = mock(Object, :read => "png")
    OpenURI.stub!(:open_uri => response)

    get '/pages.png'
    last_response.status.should == 200
  end

  it "should be unsuccessful with range parameters spanning over 30 days" do
    get '/pages.json', @params.merge!(:end => @params[:end] + 1)
    last_response.status.should == 413
  end

  it "should be unsuccessful with range parameters spanning over 30 days and recent.png" do
    response = mock(Object, :read => "png")
    OpenURI.stub!(:open_uri => response)

    get '/pages.png', @params.merge!(:end => @params[:end] + 1)
    last_response.status.should == 413
  end

  it "should be successful with range parameters" do
    get '/pages.json', @params
    last_response.body.should == "[{\"Joker\":0}]"
  end

  it "should be successful with range parameters and recent.png" do
    response = mock(Object, :read => "png")
    OpenURI.stub!(:open_uri => response)

    get '/pages.png', @params
    last_response.headers["Content-Type"] == "image/png"
  end

  it "should be successful with callback parameter" do
    get '/pages.json', @params.merge!(:callback => "test")
    last_response.body.should == "test([{\"Joker\":0}])"
  end
end
