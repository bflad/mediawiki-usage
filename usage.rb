require 'rubygems'
require 'sinatra'
require 'mysql'
require 'redis'
require 'digest/md5'
require 'json'
require 'yaml'
require 'haml'

configure :development, :production do
  THIRTY_DAYS = 2592000
  CONFIG = YAML.load_file("config/database.yml") if File.exists?("config/database.yml")
  DB = Mysql.connect(CONFIG['host'], CONFIG['username'], CONFIG['password'], CONFIG['database'])
  CACHE = Redis.new
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

    [ start_time, end_time ]
  end

  def query_to_json(sql, start_time, end_time)
    key = Digest::MD5.hexdigest("#{sql}#{start_time}#{end_time}")

    value = CACHE.get(key)
    if value.nil?
      value = DB.prepare(sql).execute(start_time, end_time).to_enum.
        inject([ ]) { |a, (k,v)| v.nil? ? {:count => k.to_i} : a << {k.to_sym => v.to_i} }.
        to_json

      CACHE.set(key, value)
      CACHE.expire(key, 1800)
    end

    value
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
  start_time, end_time = sanitize(params)

  json = case params[:splat][0]
    when "hour"
      query_to_json('SELECT HOUR(changed_at) as hour, SUM(char_changes) as total FROM changes WHERE changed_at BETWEEN ? AND ? GROUP BY HOUR(changed_at)',
        start_time,
        end_time
      )
    when "day"
      query_to_json('SELECT DAY(changed_at) as day, SUM(char_changes) as total FROM changes WHERE changed_at BETWEEN ? AND ? GROUP BY DAY(changed_at)',
        start_time,
        end_time
      )
    else
      query_to_json('SELECT SUM(char_changes) as total FROM changes WHERE changed_at BETWEEN ? AND ?',
        start_time,
        end_time
      )
    end

  params[:callback].nil? ? json : "#{params[:callback]}(#{json})"
end

get '/editors/?' do
  start_time, end_time = sanitize(params)

  json = query_to_json('SELECT DISTINCT(editor), SUM(char_changes) AS total FROM changes WHERE changed_at BETWEEN ? AND ? GROUP BY editor',
    start_time,
    end_time
  )

  params[:callback].nil? ? json : "#{params[:callback]}(#{json})"
end

get '/pages/?' do
  start_time, end_time = sanitize(params)

  json = query_to_json('SELECT DISTINCT(page), SUM(char_changes) AS total FROM changes WHERE changed_at BETWEEN ? AND ? GROUP BY page',
    start_time,
    end_time
  )

  params[:callback].nil? ? json : "#{params[:callback]}(#{json})"
end
