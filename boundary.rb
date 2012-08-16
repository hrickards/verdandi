class Verdandi::Boundaries < Mongomatic::Base
  def self.scrape
    # TODO remove
    require 'pp'

    # Read in the text from the PDF, and split on newlines
    file = File.read('/tmp/1206.txt').split("\n")

    # Split the file into pages, based upon the first line of the file
    pages = file.chunk { |g| g.include? file.first }.reject { |s, a| s }.map { |s, a| a }

    # Iterate over each page
    # TODO Actually do all pages
    pages[9..-1].each do |lines|
      # Remove the copy at the start of the page
      magic_slice "Unit Code", lines

      # Get each column
      unit_codes = magic_slice("Unit Name", lines)[0..-3]
      unit_names = magic_slice("Paper Options", lines)[0..-3]
      paper_options = magic_slice("Maximum", lines)[1..-3]
      maximum_marks = magic_slice("a*", lines)[1..-3]
      pp maximum_marks


      pp lines
    end
  end
  
  protected
  # Returns the index of the element in the passed array that includes the
  # passed string somewhere within it
  def self.nested_include(string, array)
    array.index(array.select { |l| l.include? string }.first)
  end

  # Returns the section of an array from the beginning until an element in the
  # array includes the passed string
  def self.magic_slice(string, array)
    array.slice!(0..nested_include(string, array))
  end
end

  #def self.scrape
    ## TODO remove
    #require 'pp'

    ## Read in the text from the PDF, and split on newline
    #file = File.read('/tmp/asd.txt').split("\n")

    ## Split the array of lines into an array of pages
    #unicode_string = 0xF06B.chr('UTF-8') + 0xF06C.chr('UTF-8') + 0xF06D.chr('UTF-8')
    #pages = file.chunk { |g| g == unicode_string }.reject { |s, a| s }.map { |s, a| a }

    ## Iterate over each page
    ## TODO remove index
    #pages[1..-1].each_with_index do |lines, i|
      #if i == 6
        #pp lines
        #raise "foo".inspect
      #end
      
      ## Remove the copy
      #magic_slice "Code", lines, false

      ## If the first line begins with "Code Title ", remove that part of it
      #lines[0].sub! /^Code Title /, ""

      ## If the next 11 lines are headers and grade names, remove them
      #lines.shift 11 if lines[0] == "Code" and lines[10] == "E"



      #grades_info = lines
    #end
  #end
  
#end

  ##def self.scrape
    ### Read in the text from the PDF, and split on newlin
    ##text = File.read('/tmp/sample.txt').split("\n")

    ##while not text.empty?
      ### Remove everything until the first time "Code" appears
      ##array_magic_slice ["Code", "BENG1"], text

      ### Get the codes, titles and max scaled marks of each exam
      ##codes = super_magic_slice("Title", text)
      ##titles = super_magic_slice "A-level", text
      ##max_scaled_marks = super_duper_magic_slice "Scaled Mark Grade Boundaries and A* Conversion Points", text

      ##require 'pp'
      ##pp codes
      ##pp titles
      ##pp max_scaled_marks
    ##end
    ##raise "foo".inspect

    ### Remove the grades
    ##text.slice! (0..6)

    ###grades = []
    
    #### The next twelve elements are the grades for the first two subjects, in
    #### reverse order
    ###2.times { grades << text.slice!(0..5).reverse }

    ###grades << text.slice!(0..5)
    ###grades << text.slice!(0..5).reverse

    ###transposed_grades = []
    ###text.shift
    ###raw_transposed_grades = magic_slice "Scaled mark unit grade boundaries", text
    #### See http://stackoverflow.com/questions/4800337
    ###raw_transposed_grades = raw_transposed_grades.chunk { |g| g == "" }.reject { |s, a| s }.map { |s, a| a }
    ###puts raw_transposed_grades.inspect


    ###grades.map! { |g| parse_grades g }

    ###puts grades.inspect
    ###puts text
  ##end


  ### Wrapper around magic_slice that removes any elements in the result that
  ### are blank, as well as the first element. Also removes any non-ASCII chars.
  ##def self.super_magic_slice(string, array)
    ##encoding_options = {
      ##:invalid           => :replace,  # Replace invalid byte sequences
      ##:undef             => :replace,  # Replace anything not defined in ASCII
      ##:replace           => ''         # Use a blank for those replacements
    ##}
    ##array.map! { |e| e.encode Encoding.find('ASCII'), encoding_options }
    ##magic_slice(string, array).chunk { |e| e == "" }.reject { |s, a| s }.map { |s, a| a }[0..-2]
  ##end

  ### Removes all non "-" or integral values from the array, and converts the
  ### rest to ints (if they're not "-").
  ##def self.parse_grades(array)
    ##array.select { |e| e == "-" or not e =~ /\D+/ }.map { |e| e == "-" ? "-" : e.to_i }
  ##end

  ### Wrapper around super_magic_slice that calls parse_grades on the result
  ##def self.super_duper_magic_slice(string, array)
    ##super_magic_slice(string, array).map { |e| parse_grades e }
  ##end

  ###def self.scrape
    ###html = File.read '/tmp/sample.html'

    #### Split the HTML into pages based on horizontal line rules, and skip the
    #### first page (just contains copyright info and such)
    ###pages = Nokogiri::HTML(html).xpath("//body").to_html.split("<hr>")[1..-2]

    #### For each page, split on newlines and strip any unneeded tags. 
    ###pages.map! { |p| p.split("\n").map { |e| e.gsub("<br>","") }[2..-1] }

    #### Remove the last two lines from the array - they just contain copyright
    #### info. Also, trim a copyright string from the end of the last line.
    ###pages[-1] = pages.last[0..-3]
    ###pages[-1][-1] = pages.last.last.partition("<b>").first

    #### Magically fix a problem with the HTML whereby one string is split onto
    #### different lines
    ###new_pages = []
    ###pages.each do |p|
      ###new_p = []
      ###p.each_with_index do |c, j|
        ###if is_string_field(c) and is_string_field(p[j-1]) and is_string_field(p[j+1])
          ###unless is_string_field(p[j-2])
            ###highest_index = j+2
            ###while true
              ###highest_index += 1
              ###break unless is_string_field(p[highest_index])
            ###end
            ###new_p << p[j..(highest_index-1)].join
            ###diff = highest_index-j-1
          ###end
        ###else
          ###new_p << c
        ###end
      ###end
      ###raise new_p.each_slice(9).to_a.inspect
      ###new_pages << new_p
    ###end

    ####pages.each do |p|
      ####half = p.product(p).select { |x, y| (x..y).inject (true) { |r, o| r && p.include?(o) } }
      ####half2 = half.select { |x, y| y > x and not half.include? [x, y+1] }
      ####indexes = half2.select { |x, y| not half2.include? [x-1, y] }
      ####raise indexes.inspect
    ####end


    #### Fix weird formatting that occurs at position 63 in each page
    ###pages.map! { |p| p.length > 62 ? (p[0..62] << p[63..75].join('')) + p[76..-1] : p }

    #### Slice each page into actual grade boundaries
    ###results = pages.map { |p| p.each_slice(9).to_a }

    ###require 'pp'
    ###pp results
  ###end

  ###def self.is_string_field(c)
    ###c =~ /\D+/ and c != "-"
  ###end
##end
