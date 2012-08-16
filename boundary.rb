class Verdandi::Boundaries < Mongomatic::Base
  WORKING_FILENAMES = ["gcse units.txt", "a level.txt"]
  def self.scrape
    Dir.foreach('data/boundary/aqa') do |filename|
      # TODO Do all files
      next if filename == "." or filename == ".." or not WORKING_FILENAMES.include? filename

      # Get the text content of the PDF
      text = File.open("data/boundary/aqa/#{filename}", "rb").read

      # Split on newlines and strip whitespace
      pages = text.split("\n").map { |line| line.strip.lstrip }

      # Get the year and qualification
      year = pages[5].split(" - ").last.split(" ")[0..1].join("_").downcase.to_sym
      raw_qualification = pages[6]
      qualification = raw_qualification.gsub(/[- ]/, "_").downcase.to_sym

      # Split into pages
      pages = pages.each_slice_from_approximate_value raw_qualification

      # Remove the first page (just copy), and the top of the second page and the
      # bottom of the last page
      pages.shift
      pages.shift if filename == "gcse units.txt"
      pages[0].slice_until_includes! "Code"
      pages[-1].reverse_slice_until_includes! "Version"

      # Initialise a blank array to store boundaries in
      details = []

      # Iterate over each page
      pages.each do |page|
        # If we only have copy, skip the page
        next if page == ["Max. Scaled Mark Grade Boundaries and A* Conversion Points", "Code Title Scaled Mark A* A B C D E"]

        # If the first two lines are just copy, remove them
        2.times { page.shift } if page[0..1] == ["Maximum Scaled Mark Grade Boundaries", "Code Title Scaled Mark A* A B C D E F G"]

        # Remove any copy at the end
        page.reverse_slice_until_includes! "Scaled mark unit grade boundaries"

        # Remove any lines where no candidates where entered or are invalid
        page.select! { |line| not (line.include? "No candidates were entered for this unit" or line.include? "???" )}

        # Fix duplicate lines
        page.map! { |line| fix_duplicate_line line }

        # Actually parse the details from each line
        page.map! { |line| parse_line line }

        # Add the boundaries
        details += page
      end

      pp details.length
    end
  end
  
  protected
  # Returns the line, unless everything is repeated after itself in the line,
  # in which case it fixes that
  def self.fix_duplicate_line(line)
    words = line.split " "

    first_duplicated = words[0] == words[1]

    index_of_first_grade = words.each_with_index.select { |word, i| words[i-1].downcase != "unit" and (i...words.length).inject (true) { |r, j| r and (not words[j] =~ /\D+/ or words[j] == "--" or words[j] == "-") } }.map { |word, i| i }.min
    rest_words = words[2...index_of_first_grade]
    rest_duplicated = rest_words[0...(rest_words.length/2)] == rest_words[(rest_words.length/2)..-1]

    if first_duplicated and rest_duplicated
      grades = words[index_of_first_grade..-1]
      grades.map! { |g| g.scan(/./) }.map! { |g| g[0...(g.length/2)].join("") }
      ([words[0]] + rest_words[0...(rest_words.length/2)] + grades).join " "
    else
      line
    end
  end

  def self.parse_marks(marks)
    marks.map { |mark| mark == "-" ? "-" : mark.to_i }
  end

  # Parses the details of a boundary from a passed line
  def self.parse_line(line)
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

    grade_names = case marks_string.length
                  when 6
                    %w{a_star a b c d e}.map { |x| x.to_sym }
                  when 8
                    %w{a_star a b c d e f g}.map { |x| x.to_sym }
                  when 2
                    %w{a e}.map { |x| x.to_sym }
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
