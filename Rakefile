require 'rubygems'
require 'bundler'
Bundler.require :default, :development

require_relative 'timetables_scrape'

BASE_TIMETABLE_URL = "http://www.education.gov.uk/comptimetable/"

task :scrape_raw_timetables do
  TimetablesScrape.scrape
end

task :default => [:scrape_raw_timetables] do
  puts "Running..."
end
