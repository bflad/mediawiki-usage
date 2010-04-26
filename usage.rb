require 'rubygems'
require 'sinatra'
require 'mysql2'
require 'redis'
require 'digest/md5'
require 'open-uri'
require 'gchart'
require 'json'
require 'yaml'
require 'haml'

configure :development, :production do
  THIRTY_DAYS = 2592000
  TWENTY_FOUR_HOURS = 86400
  CONFIG = YAML.load_file("config/database.yml") if File.exists?("config/database.yml")
  DB = Mysql2::Client.new(:host => CONFIG['host'], :username => CONFIG['username'], :password => CONFIG['password'], :database => CONFIG['database'])
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
    case capture
    when /\.png/
      "image/png"
    when /\.json/
      "application/json; charset=utf-8"
    else
      "application/json; charset=utf-8"
    end
  end

  def sanitize(params)
    start_time = params[:start].nil? ? (Time.now - TWENTY_FOUR_HOURS) : Time.at(params[:start].to_i)
    end_time = params[:end].nil? ? (Time.now) : Time.at(params[:end].to_i)
    difference = (end_time - start_time).to_i

    throw :halt, [413, {:message => "Request Entity Too Large"}.to_json] unless difference > 0 and difference <= THIRTY_DAYS

    content_type = capture_to_mime(params[:captures].nil? ? nil : params[:captures].last)
    headers "Content-Type" => content_type

    [ start_time, end_time, content_type ]
  end

  def query_to_json(sql, start_time, end_time)
    key = Digest::MD5.hexdigest("#{sql}#{start_time}#{end_time}")

    value = CACHE_CONNECTED ? CACHE.get(key) : nil
    if value.nil?
      value = DB.query(sql % [ start_time.strftime('%Y-%m-%d %H:%M:%S'), end_time.strftime('%Y-%m-%d %H:%M:%S') ]).to_a.
        inject([ ]) { |a, h| h = h.values; h.length > 1 ? a << {h.last => h.first.to_i} : {:count => h.first.to_i} }.
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
      data = DB.query(sql % [ start_time.strftime('%Y-%m-%d %H:%M:%S'), end_time.strftime('%Y-%m-%d %H:%M:%S') ]).to_a.
        inject({ }) { |a, h| h = h.values; a[h.last] = h.first.to_i; a }

      value = open(Gchart.pie(:size => '700x400', :data => data.values, :labels => data.keys, :bar_colors => ['0000FF']).gsub(/\|/, '%7C')).read

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

get %r{/count\/?(hour|day)?\/?(.json)?} do
  start_time, end_time, content_type = sanitize(params)

  params[:captures] ||= [ ]
  json = case params[:captures].first
    when "hour"
      sql = "SELECT HOUR(changed_at) as hour, SUM(char_changes) as total FROM changes WHERE changed_at BETWEEN '%s' AND '%s' GROUP BY HOUR(changed_at)"
    when "day"
      sql = "SELECT DAY(changed_at) as day, SUM(char_changes) as total FROM changes WHERE changed_at BETWEEN '%s' AND '%s' GROUP BY DAY(changed_at)"
    else
      sql = "SELECT SUM(char_changes) as total FROM changes WHERE changed_at BETWEEN '%s' AND '%s'"
  end

  json = query_to_json(sql, start_time, end_time)
  params[:callback].nil? ? json : "#{params[:callback]}(#{json})"
end

get %r{/editors\/?(.json|.png)?} do
  start_time, end_time, content_type = sanitize(params)

  sql = "SELECT DISTINCT(editor), SUM(char_changes) AS total FROM changes WHERE changed_at BETWEEN '%s' AND '%s' GROUP BY editor"
  case content_type
    when "image/png"
      query_to_png(sql, start_time, end_time)
    else
      json = query_to_json(sql, start_time, end_time)
      params[:callback].nil? ? json : "#{params[:callback]}(#{json})"
  end
end

get %r{/pages\/?(.json|.png)?} do
  start_time, end_time, content_type = sanitize(params)

  sql = "SELECT DISTINCT(page), SUM(char_changes) AS total FROM changes WHERE changed_at BETWEEN '%s' AND '%s' GROUP BY page"
  case content_type
    when "image/png"
      query_to_png(sql, start_time, end_time)
    else
      json = query_to_json(sql, start_time, end_time)
      params[:callback].nil? ? json : "#{params[:callback]}(#{json})"
  end
end
