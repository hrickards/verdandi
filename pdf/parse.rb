require 'pp'
require 'timeout'

class Array
  # Splits up an array from the given value
  # e.g [1,5,3,7,3,7,6,7,3,1].each_slice_from_approximate_value(3) gives
  # [[1,5],[7],[7,6,7],1]
  def each_slice_from_approximate_value(value)
    self.chunk { |el| el.include? value }.reject { |s, a| s }.map { |s, a| a }
  end
  
  # Returns the index of the element in the passed array that includes the
  # passed string somewhere within it
  def index_of_element_that_includes(string)
    self.index self.select { |l| l.include? string }.first
  end

  # Slices the array from the beginning until an element in the array includes
  # the passed string
  def slice_until_includes!(string)
    self.slice!(0..self.index_of_element_that_includes(string))
  end

  # Slices the array from the end until an element in the array includes the
  # passed string
  def reverse_slice_until_includes!(string)
    start_index = self.index_of_element_that_includes(string)
    if start_index
      self[start_index] = self[start_index].rpartition(string).first
      if self[start_index].empty?
        self.slice!(start_index..-1)
      else
        self.slice!(start_index+1..-1)
      end
    end
  end
end

# Returns the line, unless everything is repeated after itself in the line,
# in which case it fixes that
def fix_duplicate_line(line)
  words = line.split " "

  first_duplicated = words[0] == words[1]

  index_of_first_grade = words.each_with_index.select { |word, i| words[i-1].downcase != "unit" and (i...words.length).inject (true) { |r, j| r and (not words[j] =~ /\D+/ or words[j] == "--") } }.map { |word, i| i }.min
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

def parse_marks(marks)
  marks.map { |mark| mark == "-" ? "-" : mark.to_i }
end

# Parses the details of a boundary from a passed line
def parse_line(line)
  words = line.split(" ")
  code = words.shift
  line = words.join " "

  marks_string, title = line.reverse.scan(/([\d -]+) (.*)/)[0]
  marks_string.reverse!
  title.reverse!

  if title.split(" ")[-1].downcase == "unit" or (title.split(" ")[-1].downcase == "written" and marks_string.split(" ")[0].match(/\d[a-zA-Z]?/)[0] == marks_string.split(" ")[0])
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
                when 2
                  %w{a e}.map { |x| x.to_sym }
                else
                  pp line
                  pp title
                  raise "Invalid number of grades - #{marks_string.length}"
                end

  grades = Hash[grade_names.zip marks_string]

  details = [code, title, max_scaled_mark, grades]
  labels = :code, :title, :max_scaled_mark, :grades
  details = Hash[labels.zip details]

  details
end



# Get the text content of the PDF
text = File.open('sample.txt', 'rb').read

# Split into pages, and strip newlines
pages = text.split("\n").map { |line| line.strip.lstrip }.each_slice_from_approximate_value("A-level")

# Remove the first page (just copy), and the top of the second page and the
# bottom of the last page
pages.shift
pages[0].slice_until_includes! "Code"
pages[-1].reverse_slice_until_includes! "Version"

details = []

# Iterate over each page
pages.each do |page|
  # Remove any copy at the end
  page.reverse_slice_until_includes! "Scaled mark unit grade boundaries"

  # Fix duplicate lines
  page.map! { |line| fix_duplicate_line line }

  # Actually parse the details from each line
  page.map! { |line| parse_line line }

  details += page
end

pp details.length
