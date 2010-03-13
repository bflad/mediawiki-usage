require 'rubygems'
require 'sinatra'
require 'dm-core'
require 'dm-aggregates'
require 'json'
require 'haml'
require 'lib/change'

configure :production, :development do
  THIRTY_DAYS = 2592000
  TIME_FORMAT = "%Y-%m-%d %H:%M:%S"
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

helpers do
  def sanitize(params)
    throw :halt, [400, {:message => "Bad Request"}.to_json] if params[:start].nil? or params[:end].nil?
    
    start_time = Time.at(params[:start].to_i)
    end_time = Time.at(params[:end].to_i)
    difference = (end_time - start_time).to_i
    
    throw :halt, [413, {:message => "Request Entity Too Large"}.to_json] unless difference > 0 and difference <= THIRTY_DAYS
    
    [start_time, end_time, difference]
  end
  
  def query(sql, start_time, end_time)
    repository(:default).adapter.select(sql, start_time.strftime(TIME_FORMAT), end_time.strftime(TIME_FORMAT))
  end
end

get '/' do
  headers "Content-Type" => "text/html; charset=utf-8"
  haml :index  
end

get '/docs/?' do
  headers "Content-Type" => "text/html; charset=utf-8"
  haml :docs
end

get '/count/?*' do
  start_time, end_time, difference = sanitize(params)

  json = case params[:splat][0]
    when "hour"
      query('SELECT HOUR(changed_at) as hour, SUM(line_changes) as total FROM changes WHERE changed_at BETWEEN ? AND ? GROUP BY HOUR(changed_at)',
        start_time,
        end_time
      ).inject([ ]) { |output, struct| output << { struct['hour'] => struct['total'].to_i } }.to_json
    when "day"
      query('SELECT DAY(changed_at) as day, SUM(line_changes) as total FROM changes WHERE changed_at BETWEEN ? AND ? GROUP BY DAY(changed_at)',
        start_time,
        end_time
      ).inject([ ]) { |output, struct| output << { struct['day'] => struct['total'].to_i } }.to_json
    else
      total = query('SELECT SUM(line_changes) as total FROM changes WHERE changed_at BETWEEN ? AND ?',
        start_time,
        end_time
      )[0].to_i
      {:changes => total}.to_json
  end

  params[:callback].nil? ? json : "#{params[:callback]}(#{json})"
end

get '/editors/?' do
  start_time, end_time, difference = sanitize(params)

  json = query('SELECT DISTINCT(editor), SUM(line_changes) AS total FROM changes WHERE changed_at BETWEEN ? AND ? GROUP BY editor',
    start_time,
    end_time
  ).inject([ ]) { |output, struct| output << { struct['editor'] => struct['total'].to_i } }.to_json

  params[:callback].nil? ? json : "#{params[:callback]}(#{json})"
end

get '/pages/?' do
  start_time, end_time, difference = sanitize(params)

  json = query('SELECT DISTINCT(page), SUM(line_changes) AS total FROM changes WHERE changed_at BETWEEN ? AND ? GROUP BY page',
    start_time,
    end_time
  ).inject([ ]) { |output, struct| output << { struct['page'] => struct['total'].to_i } }.to_json

  params[:callback].nil? ? json : "#{params[:callback]}(#{json})"
end
