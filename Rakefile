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

task :index do
  MONGO['raw_boundaries'].create_index 'boundaries.code'
  MONGO['raw_exams'].create_index 'exam_code'
end

task :parse do
  parse
end

task :console do
  binding.pry
end

task :default => [:exams, :boundaries, :subjects, :index, :parse] do
  puts "Running..."
end
