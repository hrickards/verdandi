require 'rubygems'
require 'bundler'
Bundler.require :default, :development

module Seshat
end

require_relative 'exam'

include Seshat

Mongomatic.db = Mongo::Connection.new.db "seshat"
