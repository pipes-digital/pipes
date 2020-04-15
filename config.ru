require 'rubygems'
require 'bundler'

Bundler.require

### Enable persistent sessions using moneta ###
require 'moneta'
require 'rack/session/moneta'

use Rack::Session::Moneta,
    expire_after: 259200000,
    store: Moneta.new(:Sqlite, file: "sessions.db")
###

require './server.rb'

run Sinatra::Application.new