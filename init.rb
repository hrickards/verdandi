require 'rubygems'
require 'bundler'
Bundler.require :default, :development

module Verdandi
end

require_relative 'exam'

include Verdandi

Mongomatic.db = Mongo::Connection.new.db "verdandi"
