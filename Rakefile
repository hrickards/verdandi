require_relative 'init'

task :exams do
  Exam.scrape
end

task :boundaries do
  Boundary.scrape
end

task :subjects do
  SubjectParse.scrape
end

task :console do
  binding.pry
end

task :default => [:exams, :boundaries, :subjects] do
  puts "Running..."
end
