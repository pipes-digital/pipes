require 'rubygems'
require 'bundler'

Bundler.require

### Enable persistent sessions using moneta ###
require 'moneta'
require 'rack/session/moneta'

use Rack::Session::Moneta,
    expire_after: 2592000, # 30 days in seconds (was incorrectly set to ~8 years)
    store: Moneta.new(:Sqlite, file: "sessions.db")
###

require './server.rb'

run Sinatra::Application.new