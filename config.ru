require 'usage.rb'

set :environment, :production
set :run, false

run Sinatra::Application
