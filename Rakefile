require 'rubygems'
require 'bundler'
Bundler.require :default, :development

require_relative 'timetable'

task :scrape_raw_timetables do
  Timetable.scrape
end

task :default => [:scrape_raw_timetables] do
  puts "Running..."
end
