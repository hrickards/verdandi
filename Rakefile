require_relative 'init'

task :exams do
  Exam.scrape
end

task :boundaries do
  Boundaries.scrape
end

task :default => [:exams] do
  puts "Running..."
end
