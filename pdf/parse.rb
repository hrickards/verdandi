require 'pp'

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
    grades = words[index_of_first_grade+1..-1]
    grades.map! { |g| g.scan(/./) }.map! { |g| g[0...(g.length/2)].join("") }
    ([words[0]] + rest_words[0...(rest_words.length/2)] + grades).join " "
  else
    line
  end
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

# Iterate over each page
pages.each do |page|
  # Remove any copy at the end
  page.reverse_slice_until_includes! "Scaled mark unit grade boundaries"

  # Fix duplicate lines
  page.map! { |line| fix_duplicate_line line }

  pp page
end
