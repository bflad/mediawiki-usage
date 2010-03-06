require 'rubygems'
require 'sinatra'
require 'dm-core'
require 'dm-aggregates'
require 'json'
require 'lib/change'

configure :production, :development do
  TEN_DAYS = 864000
  @config = YAML.load_file("config/database.yml") if File.exists?("config/database.yml")
  DataMapper.setup(:default, {
    :adapter => @config['adapter'],
    :host => @config['host'],
    :username => @config['username'],
    :password => @config['password'],
    :database => @config['database']
  })
end

before do
  headers "Content-Type" => "application/json; charset=utf-8"
end

get '/' do
  haml :index
end

get '/count/?' do
  if params[:start].nil? or params[:end].nil?
    throw :halt, [400, {:message => "Bad request"}.to_json]
  else
    start_time = Time.at(params[:start].to_i)
    end_time = Time.at(params[:end].to_i)
    difference = (end_time - start_time).to_i
    
    unless difference > 0 and difference <= TEN_DAYS
      throw :halt, [413, {:message => "Request Entity Too Large"}.to_json]
    else
      {:changes => Change.sum(:line_changes, :changed_at => (start_time..end_time))}.to_json
    end
  end
end

get '/editors/?' do
  if params[:start].nil? or params[:end].nil?
    throw :halt, [400, {:message => "Bad request"}.to_json]
  else
    start_time = Time.at(params[:start].to_i)
    end_time = Time.at(params[:end].to_i)
    difference = (end_time - start_time).to_i
    
    unless difference > 0 and difference <= TEN_DAYS
      throw :halt, [413, {:message => "Request Entity Too Large"}.to_json]
    else
      results = repository(:default).adapter.select(
        'SELECT DISTINCT(editor), SUM(line_changes) AS total FROM changes WHERE changed_at >= FROM_UNIXTIME(?) AND changed_at <= FROM_UNIXTIME(?) GROUP BY editor',
        start_time.to_i,
        end_time.to_i
      )
      results.inject([ ]) { |output, struct| output << { struct['editor'] => struct['total'].to_i } }.to_json
    end
  end
end

get '/pages/?' do
  if params[:start].nil? or params[:end].nil?
    throw :halt, [400, {:message => "Bad request"}.to_json]
  else
    start_time = Time.at(params[:start].to_i)
    end_time = Time.at(params[:end].to_i)
    difference = (end_time - start_time).to_i
    
    unless difference > 0 and difference <= TEN_DAYS
      throw :halt, [413, {:message => "Request Entity Too Large"}.to_json]
    else
      results = repository(:default).adapter.select(
        'SELECT DISTINCT(page), SUM(line_changes) AS total FROM changes WHERE changed_at >= FROM_UNIXTIME(?) AND changed_at <= FROM_UNIXTIME(?) GROUP BY page',
        start_time.to_i,
        end_time.to_i
      )
      results.inject([ ]) { |output, struct| output << { struct['page'] => struct['total'].to_i } }.to_json
    end
  end
end
