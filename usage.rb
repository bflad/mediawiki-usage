require 'rubygems'
require 'sinatra'
require 'mysql'
require 'redis'
require 'digest/md5'
require 'open-uri'
require 'gchart'
require 'json'
require 'yaml'
require 'haml'

configure :development, :production do
  THIRTY_DAYS = 2592000
  CONFIG = YAML.load_file("config/database.yml") if File.exists?("config/database.yml")
  DB = Mysql.connect(CONFIG['host'], CONFIG['username'], CONFIG['password'], CONFIG['database'])
  CACHE = Redis.new

  begin
    CACHE.info
    CACHE_CONNECTED = true
  rescue Errno::ECONNREFUSED
    CACHE_CONNECTED = false
  end
end

helpers do
  def capture_to_mime(capture)
    capture =~ /\.png/ ? "image/png" : "application/json; charset=utf-8"
  end

  def sanitize(params)
    start_time = params[:start].nil? ? (Time.now - THIRTY_DAYS) : Time.at(params[:start].to_i)
    end_time = params[:end].nil? ? (Time.now) : Time.at(params[:end].to_i)
    difference = (end_time - start_time).to_i

    throw :halt, [413, {:message => "Request Entity Too Large"}.to_json] unless difference > 0 and difference <= THIRTY_DAYS

    content_type = params[:captures].nil? ? "application/json; charset=utf-8" : capture_to_mime(params[:captures].first)
    headers "Content-Type" => content_type

    [ start_time, end_time, content_type ]
  end

  def query_to_json(sql, start_time, end_time)
    key = Digest::MD5.hexdigest("#{sql}#{start_time}#{end_time}")

    value = CACHE_CONNECTED ? CACHE.get(key) : nil
    if value.nil?
      value = DB.prepare(sql).execute(start_time, end_time).to_enum.
        inject([ ]) { |a, (k,v)| v.nil? ? {:count => k.to_i} : a << {k => v.to_i} }.
        to_json

      CACHE.set(key, value) if CACHE_CONNECTED
      CACHE.expire(key, 1800) if CACHE_CONNECTED
    end

    value
  end

  def query_to_png(sql, start_time, end_time)
    key = Digest::MD5.hexdigest("#{sql}#{start_time}#{end_time}.png")

    value = CACHE_CONNECTED ? CACHE.get(key) : nil
    if value.nil?
      data = DB.prepare(sql).execute(start_time, end_time).to_enum.
        inject({ }) { |a, (k,v)| v.nil? ? a[:count] = k.to_i : a[k] = v.to_i; a }

      value = open(Gchart.pie(:size => '500x400', :data => data.values, :labels => data.keys, :bar_colors => ['0000FF']).gsub(/\|/, '%7C')).read

      CACHE.set(key, value) if CACHE_CONNECTED
      CACHE.expire(key, 1800) if CACHE_CONNECTED
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
  start_time, end_time, content_type = sanitize(params)

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

get %r{/editors\/?(recent.js|recent.png)?} do
  start_time, end_time, content_type = sanitize(params)

  sql = "SELECT DISTINCT(editor), SUM(char_changes) AS total FROM changes WHERE changed_at BETWEEN ? AND ? GROUP BY editor"
  case content_type
    when "image/png"
      query_to_png(sql, start_time, end_time)
    else
      json = query_to_json(sql, start_time, end_time)
      params[:callback].nil? ? json : "#{params[:callback]}(#{json})"
  end
end

get %r{/pages\/?(recent.js|recent.png)?} do
  start_time, end_time, content_type = sanitize(params)

  sql = "SELECT DISTINCT(page), SUM(char_changes) AS total FROM changes WHERE changed_at BETWEEN ? AND ? GROUP BY page"
  case content_type
    when "image/png"
      query_to_png(sql, start_time, end_time)
    else
      json = query_to_json(sql, start_time, end_time)
      params[:callback].nil? ? json : "#{params[:callback]}(#{json})"
  end
end
