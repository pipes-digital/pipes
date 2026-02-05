require 'rubygems'
require 'bundler'

Bundler.require

require './server.rb'

run Sinatra::Application.new