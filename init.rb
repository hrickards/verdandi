require 'rubygems'
require 'bundler'
Bundler.require :default, :development

require_relative 'timetable'

Mongomatic.db = Mongo::Connection.new.db "seshat"
