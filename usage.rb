require 'rubygems'
require 'sinatra'
require 'sqlite3'
require 'dm-core'
require 'dm-aggregates'
require 'json'
require 'lib/change'

configure :production, :development do
  DataMapper.setup(:default, ENV['DATABASE_URL'] || "sqlite3://#{Dir.pwd}/usage.db")
end

before do
  headers "Content-Type" => "application/json; charset=utf-8"
end

get '/' do
  start_time = Time.at(params[:start].to_i)
  end_time = Time.at(params[:end].to_i)
  difference = (end_time - start_time).to_i

  if params[:start].nil? or params[:end].nil? or difference <= 0
    throw :halt, [400, {:message => "Bad request"}.to_json]
  elsif difference > 864000
    throw :halt, [413, {:message => "Request Entity Too Large"}.to_json]
  else
    {:changes => Change.sum(:line_changes, :changed_at => (Time.at(params[:start].to_i)..Time.at(params[:end].to_i))) }.to_json
  end
end

get '/editor/?' do
  start_time = Time.at(params[:start].to_i)
  end_time = Time.at(params[:end].to_i)
  difference = (end_time - start_time).to_i

  if params[:start].nil? or params[:end].nil? or difference <= 0
    throw :halt, [400, {:message => "Bad request"}.to_json]
  elsif difference > 864000
    throw :halt, [413, {:message => "Request Entity Too Large"}.to_json]
  else
    results = repository(:default).adapter.select(
      'SELECT DISTINCT(editor), SUM(line_changes) FROM changes GROUP BY editor ORDER BY editor'
    )

    output = [ ]
    results.each do |result|
      output << { result["editor"] => result["sum(line_changes)"] }
    end
    output.to_json
  end
end
