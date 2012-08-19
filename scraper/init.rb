# Require gems and other libs
require 'rubygems'
require 'bundler'
Bundler.require :default, :development
require 'open-uri'
require 'pp'

# Require and include application files
module Verdandi
end

require_relative 'qualification'
require_relative 'boundary'
require_relative 'exam'

require_relative 'scrape/exam'
require_relative 'scrape/boundary'
require_relative 'scrape/subject'
require_relative 'scrape/parse'

include Verdandi


# Database config
mongo_uri = URI.parse 'mongodb://localhost:27017/verdandi'
MONGO = Mongo::Connection.new(mongo_uri.host, mongo_uri.port).db(mongo_uri.path.gsub /^\//, '')
MONGO.authenticate mongo_uri.user, mongo_uri.password if mongo_uri.user and mongo_uri.password

Mongoid.load! "mongoid.yml", :development
