class Timetable
  BASE_TIMETABLE_URL = "http://www.education.gov.uk/comptimetable/"

  # Scrape the timetables data
  def self.scrape
    # Initialise a new browser to scrape the timetables with, using a
    # believable user agent. They don't seem to be checking user agents at
    # this time, but spoofing one can't hurt.
    browser = Mechanize.new { |b| b.user_agent_alias = "Linux Firefox" }

    # Get the intro page of the timetables sites
    page = browser.get BASE_TIMETABLE_URL + "/Default.aspx"

    # Submit the form accepting the T&Cs. ASP.Net does some really weird stuff
    # in place of just using links, but the below (captured from the POST
    # request sent when using their site manually) should work.
    page.form_with(:name => 'aspnetForm') do |f|
      f['ctl00$mainContent$accept.x'] = 50
      f['ctl00$mainContent$accept.y'] = 19
      page = f.submit()
    end

    # Scrape all the exams in all the sessions
    scrape_all_exam_sessions page
  end

  protected
  # Scrape all the exams in all the sessions
  def self.scrape_all_exam_sessions(page)
    # Get a list of all exam sessions
    sessions = page.form_with(:name => 'search').
                    field_with(:name => 'UCBasicSearch$ddSession').
                    options

    # Scrape each session
    sessions.each_with_index do |session, index|
      # Submit the search form to find all subjects in that session. Again has
      # to do the weird ASP.Net stuff.
      page.form_with(:name => 'search') do |f|
        f['UCBasicSearch$ddSession'] = session
        f['UCBasicSearch$showAllSub.x'] = 150
        f['UCBasicSearch$showAllSub.y'] = 24

        # Scrape all exam subjects in the session
        scrape_exam_subjects f.submit(), index
      end
    end
  end

  # Scrape all exam subjects in a session
  def self.scrape_exam_subjects(page, session_number)
    # See subjects beginning with any letter
    page.form_with(:name => 'search') do |f|
      f['UCBasicSearch2$UCSearchByLetter$btnAll'] = 'All'

      page = f.submit()
    end

    # Get a list of all subjects
    subjects = page.parser.xpath(
      '//input[
        contains(@name, "UCBasicSearch2$UCPostBackSubjectList$subjectsRepeater")
        and contains(@name, "SubjectList")
        and contains(@name, "subjectName")
      ]')

    # Initialise a new progress bar to show progress visually
    pbar = ProgressBar.new "Session #{session_number}", subjects.count

    # Scrape the exams for each subject
    subjects.each do |subject|
      # The form POST data is even weirder here
      page.form_with(:name => 'search') do |f|
        f[subject['name']] = subject['value']

        # Scrape all pages of exams for that subject
        scrape_exam_page_and_look_for_next_link f.submit()
      end

      pbar.inc
    end

    pbar.finish
  end

  # Scrape all continuous pages of exams, starting with the one passed
  def self.scrape_exam_page_and_look_for_next_link(page)
    # Actually scrape the page
    scrape_exam_page page

    # Find the next page button, if it exists
    next_button = page.parser.xpath("//input[@name='UCResultsTable$topNavigation$btnNext']").first

    # If it does exist, click it and scrape the resulting page
    if next_button
      page.form_with(:name => 'search') do |f|
        f['UCResultsTable$topNavigation$btnNext'] = 'Next >'

        page = f.submit()
      end
      scrape_exam_page_and_look_for_next_link page
    end
  end

  # Actually scrape exams from the passed page
  def self.scrape_exam_page(page)
    # Get the results table
    results = page.parser.xpath("//table[@class='results']").first

    # Save it into Redis
  end
end
