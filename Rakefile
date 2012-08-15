require_relative 'init'

task :scrape_raw_timetables do
  Exam.scrape
end

task :parse_raw_timetables do
  Exam.parse
end

task :default => [:scrape_raw_timetables, :parse_raw_timetables] do
  puts "Running..."
end
