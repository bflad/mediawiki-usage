require File.join(File.dirname(__FILE__), '..', 'usage.rb')

require 'rubygems'
require 'sinatra'
require 'haml'
require 'rack/test'
require 'spec'
require 'spec/autorun'
require 'spec/interop/test'

set :environment, :test
set :run, false
set :raise_errors, true
set :logging, false
