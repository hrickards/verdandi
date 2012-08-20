# encoding: utf-8

module Verdandi
  WORKING_FILENAMES = ["a level.txt"]
  def parse_boundaries
    # Drop old mongo results
    MONGO['raw_boundaries'].drop

    # For each data file
    Dir.foreach('data/boundary/aqa') do |filename|
      # If it's actually a data file, and we know how to parse it
      next if filename == "." or filename == ".." or not WORKING_FILENAMES.include? filename

      # Get the text content of the PDF
      file = File.open("data/boundary/aqa/#{filename}", "r:windows-1251:utf-8").read

      # Create a new parser, and parse the file
      parser = BoundariesParser.new file
      results = parser.parse

      # Embed nested units into their parents
      results[:boundaries] = embed_nested_units results[:boundaries]

      # Insert the results into Mongo
      MONGO['raw_boundaries'].insert results
    end
  end

  protected
  def embed_nested_units(units)
    # Swap the select and map for recursive, but slower, nesting
    units.select { |unit| not unit[:parent_code] }.map { |unit| embed_nested_units_for_parent(unit, units) }
  end

  def embed_nested_units_for_parent(parent, units)
    nested_units = units.find_all { |unit| unit[:parent_code] == parent[:code] }
    parent[:sub_units] = nested_units.map { |unit| remove_parent_code unit } unless nested_units.empty?

    parent
  end

  def remove_parent_code(unit)
    unit.delete :parent_code
    unit
  end
end

class Verdandi::BoundariesParser
  # Matches all valid boundary lines
  PARSE_REGEXP = /^([\w\/]+) ((1?\d?[^\d]+1?\d? )+)(([\d-]* )*[\d-]+)/
  # Anything matching this is not a valid boundary line
  COPY_REGEXP = /^(Unit)|(The Assessment and Qualifications Alliance)|(Copyright)|(Version)|(and a registered charity)|(Registered address)|(Published)/
  # Anything matching this is not a grade name
  GRADE_REGEXP = /(Code)|(Subject)|(Title)|(Scaled)|(Mark)/

  # Initialisation method
  def initialize(file)
    @file = file
  end

  # Wrapper method to parse the file
  def parse
    preprocess_file

    # Get the year, qualification and split string of the file
    get_year
    get_qualification
    get_split_string

    # Get the grade descriptors
    get_grade_names

    # Remove any non-valid boundary lines
    remove_non_boundary_lines

    # Actually parse the boundaries from each line
    parse_boundaries

    # Return a generated hash
    make_details_hash
  end

  # Get the grade names
  def get_grade_names
    raw_grades = @lines[20].split(" ").select { |word| not word =~ GRADE_REGEXP }
    @grade_names = raw_grades.map { |grade| parse_grade grade }
  end

  # Generate a hash of details about the boundaries
  def make_details_hash
    { :year => @year, :qualification => @qualification, :boundaries => @boundaries }
  end

  # Preprocess the file to split into an array, etc
  def preprocess_file
    @lines = @file.split("\n").map { |line| line.strip.lstrip }
  end

  # Get the year from a boundaries file
  def get_year
    @year = @lines[5].split(" - ").last.split(" ")[0..1].join("_").downcase.to_sym
  end

  # Get the qualification from a boundaries file
  def get_qualification
    #@qualification = case @lines[6]
    #else
      #@lines[6].gsub(/[()]/, '').gsub(/ [-–_] /, "_").gsub(/[- ]/, "_").downcase.to_sym
    #end
    @qualification = @lines[6].gsub(/[()]/, '').gsub(/ [-–_] /, "_").gsub(/[- ]/, "_").downcase.to_sym
  end

  # Get the split string from a boundaries file
  def get_split_string
    #@split_string = case @lines[6]
    #else
      #@lines[6]
    #end
    @split_string = @lines[6]
  end

  # Remove any non-valid boundary lines
  def remove_non_boundary_lines
    # Remove any lines that aren't valid boundary lines
    @lines.select! { |line| is_valid_boundary_line line }
  end

  # Parse the boundaries from each line
  def parse_boundaries
    @boundaries = @lines.map { |line| parse_boundary_from_line line }
  end

  # Returns whether or not the line contains valid boundary details
  def is_valid_boundary_line(line)
    line =~ PARSE_REGEXP and not line =~ COPY_REGEXP
  end

  # Parse the boundary from a line
  def parse_boundary_from_line(line)
    code, title, _, marks, _ = line.scan(PARSE_REGEXP)[0]
    title = title.strip
    marks = parse_marks marks

    max_scaled_mark = marks.shift
    grades, nested = zip_grades marks

    details_hash = {:code => code, :title => title, :max_scaled_mark => max_scaled_mark, :grades => grades }

    if nested
      details_hash[:parent_code] = @last_code
    else
      @last_code = code
    end

    details_hash
  end

  # Convert numeric marks to numbers
  def parse_marks(marks)
    marks.split(" ").map { |mark| mark == "-" ? "-" : mark.to_i }
  end

  # Turn a grade string into a real grade
  def parse_grade(grade)
    grade.downcase.gsub("*", "_star").to_sym
  end

  # Turn an array of grades into a hash of grades
  def zip_grades(grades)
    case grades.length
    when @grade_names.length
      [Hash[@grade_names.zip grades], false]
    when 2
      unless @qualification == :a_level
        puts "Only 2 grades in this boundary, when there should be #{grades.length}"
        puts "Guessing those grades are #{@grade_names[1]} and #{@grade_names[-1]}, and this is a sub-unit"
        puts "But that's usually only true for A level boundaries (this is a #{@qualification} exam)"
      end
      [Hash[[@grade_names[1], @grade_names[-1]].zip grades], true]
    else
      raise "Hmm... #{grades.length} grades #{grades.length > @grade_names.length ? "seems to be a bit too many" : "doesn't seem to be enough"}"
    end
  end
end

  #def self.fix_duplicate_line(line)
    #words = line.split " "

    #first_duplicated = words[0] == words[1]

    #index_of_first_grade = words.each_with_index.select { |word, i| words[i-1].downcase != "unit" and (i...words.length).inject (true) { |r, j| r and (not words[j] =~ /\D+/ or words[j] == "--" or words[j] == "-") } }.map { |word, i| i }.min
    #begin
      #rest_words = words[2...index_of_first_grade]
      #rest_duplicated = rest_words[0...(rest_words.length/2)] == rest_words[(rest_words.length/2)..-1]

      #if first_duplicated and rest_duplicated
        #grades = words[index_of_first_grade..-1]
        #grades.map! { |g| g.scan(/./) }.map! { |g| g[0...(g.length/2)].join("") }
        #([words[0]] + rest_words[0...(rest_words.length/2)] + grades).join " "
      #else
        #line
      #end
    #rescue Exception
      #raise "Failed fixing duplicate line on #{line}"
    #end
  #end

    #grade_names = case [marks_string.length, qualification]
                  #when [8, :gcse_units]
                    #[:a_star, :a, :b, :c, :d, :e, :f, :g]
                  #when [8, :gcse_non_unitised_subjects]
                    #[:a_star, :a, :b, :c, :d, :e, :f, :g]
                  #when [3, :elc]
                    #[:level_3, :level_2, :level_1]
                  #when [6, :a_level]
                    #[:a_star, :a, :b, :c, :d, :e]
                  #when [6, :applied_a_level]
                    #[:a_star, :a, :b, :c, :d, :e]
                  #when [6, :fsmq_advanced_pilot]
                    #[:a_star, :a, :b, :c, :d, :e]
                  #when [6, :diploma_advanced]
                    #[:a_star, :a, :b, :c, :d, :e]
                  #when [3, :diploma_level_1]
                    #[:a_star, :a, :b]
                  #when [4, :diploma_level_2]
                    #[:a_star, :a, :b, :c]
                  #when [3, :fcse]
                    #[:distinction, :merit, :pass]
                  #when [2, :a_level]
                    #[:a, :e]
                  #when [5, :fsmq_foundation_and_intermediate_pilot]
                    #[:a, :b, :c, :d, :e]
                  #when [2, :fsmq_foundation_and_intermediate_pilot]
                    #[:a, :e]
                  #when [5, :fsmq]
                    #[:a, :b, :c, :d, :e]
                  #when [2, :fsmq]
                    #[:a, :e]
                  #when [1, :functional_skills_level_1]
                    #[:level_1_boundary]
                  #when [1, :functional_skills_level_2]
                    #[:level_2_boundary]
                  #else
                    #pp line
                    #pp title
                    #pp marks_string
                    #raise "Invalid number of grades - #{marks_string.length}"
                  #end

    #grades = Hash[grade_names.zip marks_string]

    #details = [code, title, max_scaled_mark, grades]
    #labels = :code, :title, :max_scaled_mark, :grades
    #details = Hash[labels.zip details]

    #details
  #end
#end
