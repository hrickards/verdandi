# Require gems
require 'rubygems'
require 'bundler'
Bundler.require :default, :development


# Require and include application files
module Verdandi
end

require_relative 'exam'

include Verdandi


# Database config
Mongomatic.db = Mongo::Connection.new.db "verdandi"
uri = URI.parse(ENV["REDISTOGO_URL"] || 'redis://localhost:6379/')
REDIS = Redis.new :host => uri.host, :port => uri.port, :password => uri.password
