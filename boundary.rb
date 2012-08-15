class Verdandi::Boundaries < Mongomatic::Base
  def self.scrape
    html = File.read '/tmp/sample.html'

    # Split the HTML into pages based on horizontal line rules, and skip the
    # first page (just contains copyright info and such)
    pages = Nokogiri::HTML(html).xpath("//body").to_html.split("<hr>")[1..-2]

    # For each page, split on newlines and strip any unneeded tags. 
    pages.map! { |p| p.split("\n").map { |e| e.gsub("<br>","") }[2..-1] }

    # Remove the last two lines from the array - they just contain copyright
    # info. Also, trim a copyright string from the end of the last line.
    pages[-1] = pages.last[0..-3]
    pages[-1][-1] = pages.last.last.partition("<b>").first

    # Magically fix a problem with the HTML whereby one string is split onto
    # different lines
    pages.each do |p|
      half = p.product(p).select { |x, y| (x..y).inject (true) { |r, o| r && p.include?(o) } }
      half2 = half.select { |x, y| y > x and not half.include? [x, y+1] }
      indexes = half2.select { |x, y| not half2.include? [x-1, y] }
      raise indexes.inspect
    end


    # Fix weird formatting that occurs at position 63 in each page
    pages.map! { |p| p.length > 62 ? (p[0..62] << p[63..75].join('')) + p[76..-1] : p }

    # Slice each page into actual grade boundaries
    results = pages.map { |p| p.each_slice(9).to_a }

    require 'pp'
    pp results
  end
end
