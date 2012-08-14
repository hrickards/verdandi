class TimetablesScrape
  BASE_TIMETABLE_URL = "http://www.education.gov.uk/comptimetable/"

  def self.scrape
    starting_url = "#{BASE_TIMETABLE_URL}/Default.aspx"

    @browser = Mechanize.new do |browser|
      browser.user_agent_alias = "Linux Firefox"
    end
    page = @browser.get starting_url

    page.form_with(:name => 'aspnetForm') do |f|
      f['ctl00$mainContent$accept.x'] = 50
      f['ctl00$mainContent$accept.y'] = 19
      page = f.submit()
    end

    scrape_exam_session page
  end

  protected
  def self.scrape_exam_session(page)
    page.form_with(:name => 'search').field_with(:name => 'UCBasicSearch$ddSession').options.each_with_index do |option, index|
      puts "Scraping session no. #{index}"
      page.form_with(:name => 'search') do |f|
        f['UCBasicSearch$ddSession'] = option
        f['UCBasicSearch$showAllSub.x'] = 150
        f['UCBasicSearch$showAllSub.y'] = 24

        scrape_exam_subjects f.submit()
      end
    end
  end

  def self.scrape_exam_subjects(page)
    page.form_with(:name => 'search') do |f|
      f['UCBasicSearch2$UCSearchByLetter$btnAll'] = 'All'

      page = f.submit()
    end

    scrape_exam_subject page
  end

  def self.scrape_exam_subject(page)
    subjects = page.parser.xpath('//input[contains(@name, "UCBasicSearch2$UCPostBackSubjectList$subjectsRepeater") and contains(@name, "SubjectList") and contains(@name, "subjectName")]')
    subjects.each do |subject|
      puts "Scraping #{subject['value']}"
      page.form_with(:name => 'search') do |f|
        f[subject['name']] = subject['value']
        scrape_exam_page_and_look_for_next_link f.submit()
      end
    end
  end

  def self.scrape_exam_page_and_look_for_next_link(page)
    scrape_exam_page page

    next_button = page.parser.xpath("//input[@name='UCResultsTable$topNavigation$btnNext']").first
    if next_button
      page.form_with(:name => 'search') do |f|
        f['UCResultsTable$topNavigation$btnNext'] = 'Next >'

        page = f.submit()
      end
      scrape_exam_page_and_look_for_next_link page
    end
  end

  def self.scrape_exam_page(page)
    puts "Scraping"
    results = page.parser.xpath("//table[@class='results']").first
  end
end
