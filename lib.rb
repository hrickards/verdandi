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

