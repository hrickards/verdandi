require_relative 'init'

task :exams do
  scrape_exams
end

task :boundaries do
  parse_boundaries
end

task :subjects do
  parse_subjects
end

task :console do
  binding.pry
end

task :default => [:exams, :boundaries, :subjects] do
  puts "Running..."
end
