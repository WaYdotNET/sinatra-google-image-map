require 'bundler'
require './config/init.rb'

Bundler.require

require './rackapp.rb'
run MyApp
