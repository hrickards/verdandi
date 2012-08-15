# Require gems and other libs
require 'rubygems'
require 'bundler'
Bundler.require :default, :development
require 'open-uri'


# Require and include application files
module Verdandi
end

require_relative 'exam'
require_relative 'boundary'

include Verdandi


# Database config
mongo_uri = URI.parse(ENV['MONGOHQ_URL'] || 'mongodb://localhost:27017/verdandi')
Mongomatic.db = Mongo::Connection.new(mongo_uri.host, mongo_uri.port).db(mongo_uri.path.gsub /^\//, '')
Mongomatic.db.authenticate mongo_uri.user, mongo_uri.password if mongo_uri.user and mongo_uri.password

redis_uri = URI.parse(ENV["REDISTOGO_URL"] || 'redis://localhost:6379/')
REDIS = Redis.new :host => redis_uri.host, :port => redis_uri.port, :password => redis_uri.password
