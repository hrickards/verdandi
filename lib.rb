class Array
  # Splits up an array from the given value
  # e.g [1,5,3,7,3,7,6,7,3,1].each_slice_from_approximate_value(3) gives
  # [[1,5],[7],[7,6,7],1]
  def each_slice_from_approximate_value(value)
    self.chunk { |el| el.include? value }.reject { |s, a| s }.map { |s, a| a }
  end

  def each_slice_from_beginning_value(value)
    self.chunk { |el| el[0...value.length] == value }.reject { |s, a| s }.map { |s, a| a }
  end
  
  # Returns the index of the element in the passed array that includes the
  # passed string somewhere within it
  def index_of_element_that_includes(string)
    self.index self.select { |l| l.include? string }.first
  end

  def nested_index_of_element_that_includes(string)
    self.index self.select { |l| not l.select { |m| m.include? string }.empty? }.first
  end

  # Slices the array from the beginning until an element in the array includes
  # the passed string
  def slice_until_includes!(string)
    self.slice!(0..self.index_of_element_that_includes(string))
  end

  def nested_slice_until_includes!(string, include_separator)
    self.slice!(0..self.nested_index_of_element_that_includes(string)-(include_separator ? 1 : 0))
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

  def mid_slice_until_includes!(string1, string2)
    start_index = self.index_of_element_that_includes string1
    end_index = self.index_of_element_that_includes string2
    if start_index and end_index
      self[start_index] = self[start_index].rpartition(string1).first
      if self[start_index].empty?
        self.slice!(start_index..end_index)
      else
        self.slice!(start_index+1..end_index)
      end
    end
  end

  def last_slice_includes!(string)
    self[-1] = self[-1].rpartition(string).first if self[-1].include? string
  end
end

