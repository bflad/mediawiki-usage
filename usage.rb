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

helpers do
  def structs_to_hashes(structs, k1, k2)
    structs.inject([ ]) { |output, struct| output << { struct[k1] => struct[k2] } }
  end
end

get '/count/?' do
  start_time = Time.at(params[:start].to_i)
  end_time = Time.at(params[:end].to_i)
  difference = (end_time - start_time).to_i

  if params[:start].nil? or params[:end].nil? or difference <= 0
    throw :halt, [400, {:message => "Bad request"}.to_json]
  elsif difference > 864000
    throw :halt, [413, {:message => "Request Entity Too Large"}.to_json]
  else
    {:changes => Change.sum(:line_changes, :changed_at => (start_time..end_time))}.to_json
  end
end

get '/editors/?' do
  results = repository(:default).adapter.select(
    'SELECT DISTINCT(editor), SUM(line_changes) AS totals FROM changes GROUP BY editor ORDER BY editor'
  )
  structs_to_hashes(results, "editor", "totals").to_json
end

get '/pages/?' do
  results = repository(:default).adapter.select(
    'SELECT DISTINCT(topic), SUM(line_changes) as totals FROM changes GROUP BY topic ORDER BY topic'
  )
  structs_to_hashes(results, "topic", "totals").to_json
end
