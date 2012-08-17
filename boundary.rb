# encoding: utf-8

class Verdandi::Boundaries < Mongomatic::Base
  WORKING_FILENAMES = ["gcse units.txt", "a level.txt", "applied a level.txt", "diploma advanced.txt", "diploma levels 1 and 2.txt", "elc.txt", "fcse.txt", "fsmq advanced pilot.txt", "fsmq foundation and intermediate pilot.txt", "fsmq.txt"]
  def self.scrape
    Dir.foreach('data/boundary/aqa') do |filename|
      # TODO Do all files
      next if filename == "." or filename == ".." or not WORKING_FILENAMES.include? filename

      # Get the text content of the PDF
      text = File.open("data/boundary/aqa/#{filename}", "r:windows-1251:utf-8").read

      # Split on newlines and strip whitespace
      pages = text.split("\n").map { |line| line.strip.lstrip }

      # Get the year and qualification
      year = pages[5].split(" - ").last.split(" ")[0..1].join("_").downcase.to_sym
      raw_qualification = pages[6]
      qualification = raw_qualification.gsub(/[()]/, '').gsub(/ [-–_] /, "_").gsub(/[- ]/, "_").downcase.to_sym

      # Split into pages
      pages = pages.each_slice_from_beginning_value raw_qualification

      # Remove the first page (just copy), and the top of the second page and the
      # bottom of the last page
      pages.shift
      pages.shift if qualification == :gcse_units or qualification == :elc or qualification == :fcse or qualification == :fsmq
      pages.pop if qualification == :fcse or qualification == :fsmq_advanced_pilot or qualification == :fsmq_foundation_and_intermediate_pilot
      pages[0].slice_until_includes! "Code"
      pages[-1].reverse_slice_until_includes! "Version"

      # Initialise a blank array to store boundaries in
      details = []

      # Iterate over each page
      pages.each do |page|
        # If we only have copy, skip the page
        next if page == ["Max. Scaled Mark Grade Boundaries and A* Conversion Points", "Code Title Scaled Mark A* A B C D E"] or page == ["Max Scaled Mark Grade Boundaries and A* Conversion Points", "Code Title Scaled Mark A* A B C D E"] or page == ["Maximum", "Code Title Scaled Mark A* A B C D E", "Scaled Mark Grade Boundaries"]

        # If the first two lines are just copy, remove them
        2.times { page.shift } if page[0..1] == ["Maximum Scaled Mark Grade Boundaries", "Code Title Scaled Mark A* A B C D E F G"]
        2.times { page.shift } if page[0..1] == ["Maximum Scaled Mark Grade Boundaries", "Code Title Scaled Mark A B C D E"]
        2.times { page.shift } if page[0..1] == ["Maximum Scaled Mark Grade Boundaries", "Code Title Scaled Mark Level 3 Level 2 Level 1"]

        page.last_slice_includes! "Scaled mark unit grade boundaries"
        page.last_slice_includes! "Scaled mark grade boundaries"
        page.last_slice_includes! "Scaled Mark Grade Boundaries"
        page.mid_slice_until_includes! "Scaled mark unit grade boundaries", "Code Title Scaled Mark A* A B C D E"
        page.mid_slice_until_includes! "Scaled mark unit grade boundaries", "Code Title Scaled Mark A* A B"
        2.times { page.mid_slice_until_includes! "Diploma Principal Learning Units Level 1", "Code Title Scaled Mark A* A B" }

        # Remove any lines where no candidates where entered or are invalid
        page.select! { |line| not (line.include? "No candidates were entered for this unit" or line == "???" or line.include? "no candidates were entered for this unit" or line.empty?)}

        # Fix duplicate lines
        page.map! { |line| fix_duplicate_line line }

        # Actually parse the details from each line
        page.map! { |line| parse_line line, qualification }

        # Add the boundaries
        details += page
      end

      record = {
        :year => year,
        :qualification => qualification,
        :boundaries => details
      }

      pp({ :year => year,
        :qualification => qualification,
        :count => details.count
      })

      #pp record
    end
  end
  
  protected
  # Returns the line, unless everything is repeated after itself in the line,
  # in which case it fixes that
  def self.fix_duplicate_line(line)
    words = line.split " "

    first_duplicated = words[0] == words[1]

    index_of_first_grade = words.each_with_index.select { |word, i| words[i-1].downcase != "unit" and (i...words.length).inject (true) { |r, j| r and (not words[j] =~ /\D+/ or words[j] == "--" or words[j] == "-") } }.map { |word, i| i }.min
    begin
      rest_words = words[2...index_of_first_grade]
      rest_duplicated = rest_words[0...(rest_words.length/2)] == rest_words[(rest_words.length/2)..-1]

      if first_duplicated and rest_duplicated
        grades = words[index_of_first_grade..-1]
        grades.map! { |g| g.scan(/./) }.map! { |g| g[0...(g.length/2)].join("") }
        ([words[0]] + rest_words[0...(rest_words.length/2)] + grades).join " "
      else
        line
      end
    rescue Exception
      raise "Failed fixing duplicate line on #{line}"
    end
  end

  def self.parse_marks(marks)
    marks.map { |mark| mark == "-" ? "-" : mark.to_i }
  end

  # Parses the details of a boundary from a passed line
  def self.parse_line(line, qualification)
    words = line.split(" ")
    code = words.shift
    line = words.join " "

    marks_string, title = line.reverse.scan(/([\d -]+) (.*)/)[0]
    marks_string.reverse!
    title.reverse!

    if title.split(" ")[-1].downcase == "unit" or ((title.split(" ")[-1].downcase == "written" or title.split(" ")[-1].downcase == "paper") and marks_string.split(" ")[0].match(/\d[a-zA-Z]?/)[0] == marks_string.split(" ")[0])
      title = "#{title} #{marks_string.split(" ")[0]}"
      marks_string = marks_string.split(" ")[1..-1].join " "
    end





    if [code, title, marks_string].inject (false) { |r, o| r or o.nil? or o.empty? }
      pp code
      pp title
      pp marks_string
      raise "Error parsing line - #{line}"
    end

    marks_string = marks_string.split " "
    max_scaled_mark = marks_string.shift

    marks_string = parse_marks marks_string

    grade_names = case [marks_string.length, qualification]
                  when [8, :gcse_units]
                    [:a_star, :a, :b, :c, :d, :e, :f, :g]
                  when [3, :elc]
                    [:level_3, :level_2, :level_1]
                  when [6, :a_level]
                    [:a_star, :a, :b, :c, :d, :e]
                  when [6, :applied_a_level]
                    [:a_star, :a, :b, :c, :d, :e]
                  when [6, :fsmq_advanced_pilot]
                    [:a_star, :a, :b, :c, :d, :e]
                  when [6, :diploma_advanced]
                    [:a_star, :a, :b, :c, :d, :e]
                  when [3, :diploma_levels_1_and_2]
                    [:a_star, :a, :b]
                  when [3, :fcse]
                    [:distinction, :merit, :pass]
                  when [2, :a_level]
                    [:a, :e]
                  when [5, :fsmq_foundation_and_intermediate_pilot]
                    [:a, :b, :c, :d, :e]
                  when [2, :fsmq_foundation_and_intermediate_pilot]
                    [:a, :e]
                  when [5, :fsmq]
                    [:a, :b, :c, :d, :e]
                  when [2, :fsmq]
                    [:a, :e]
                  else
                    pp line
                    pp title
                    pp marks_string
                    raise "Invalid number of grades - #{marks_string.length}"
                  end

    grades = Hash[grade_names.zip marks_string]

    details = [code, title, max_scaled_mark, grades]
    labels = :code, :title, :max_scaled_mark, :grades
    details = Hash[labels.zip details]

    details
  end
end
