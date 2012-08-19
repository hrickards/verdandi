module Verdandi
  def scrape_exams
    ExamsScraper.scrape
  end
end

class Verdandi::ExamsScraper
  BASE_TIMETABLE_URL = "http://www.education.gov.uk/comptimetable/"
  EXAM_DETAILS_KEYS = [
    :session,
    :awarding_body,
    :qualification,
    :title,
    :exam_code,
    :duration,
    :date,
    :start_time,
    :subject
  ]

  # Parse the scraped timetables data and store it into Mongo
  def self.parse(results, subject_name)
    # Get all raw HTML tables of results from Redis, convert them to a
    # Nokogiri structure that's useable, get all cells in each row that are
    # results cells, tidy up the text inside each cell and finally flatten
    # the results so that each element in results contains exam details, not
    # an array of all exam details in one of the HTML tables.
    results = results.xpath(
        '//table[
          @id="UCResultsTable_resultsTbl"
        ]//tr[
          td/@class = "results noprint"
        ]'
      ).map { |r| r.xpath("td[not(input)]").map { |d| d.text.strip.lstrip } }

    # Add the subject name to each result
    results.map! { |r| r << subject_name }

    # Turn each exam details into a hash, rather than array
    results.map! { |r| Hash[EXAM_DETAILS_KEYS.zip(r)] }

    results
  end

  # Scrape the timetables data
  def self.scrape
    # Remove old Mongo data
    MONGO['raw_exams'].drop

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

      # Scrape all the exams in all the sessions
      scrape_all_exam_sessions f.submit()
    end
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

      # Get a list of all subjects
      subjects = page.parser.xpath(
        '//input[
        contains(@name, "UCBasicSearch2$UCPostBackSubjectList$subjectsRepeater")
        and contains(@name, "SubjectList")
        and contains(@name, "subjectName")
      ]'
      )

      # Initialise a new progress bar to show progress visually
      pbar = ProgressBar.new "Session #{session_number}", subjects.count

      # Scrape the exams for each subject
      subjects.each do |subject|
        pbar.inc

        # The form POST data is even weirder here
        page.form_with(:name => 'search') do |f|
          f[subject['name']] = subject['value']

          # Scrape all pages of exams for that subject
          page = f.submit()
          scrape_exam_page_and_look_for_next_link page, subject['value']
        end
      end

      pbar.finish
    end
  end

  # Scrape all continuous pages of exams, starting with the one passed
  def self.scrape_exam_page_and_look_for_next_link(page, subject_name)
    # Actually scrape the page
    scrape_exam_page page, subject_name

    # Find the next page button, if it exists
    next_button = page.parser.xpath(
      "//input[
        @name='UCResultsTable$topNavigation$btnNext'
      ]"
    ).first

    # If it does exist, click it and scrape the resulting page
    if next_button
      page.form_with(:name => 'search') do |f|
        f['UCResultsTable$topNavigation$btnNext'] = 'Next >'

        scrape_exam_page_and_look_for_next_link f.submit(), subject_name
      end
    end
  end

  # Actually scrape exams from the passed page
  def self.scrape_exam_page(page, subject_name)
    unless page.parser.xpath("//div[@id='UCResultsTable_pnlNoMoreResults']").empty?
      puts "Hmm... no results. That's strange."
      return
    end

    begin
      # Get the results table
      results = page.parser.xpath("//table[@class='results']").first

      results = parse results, subject_name
      
      # Store each result in Mongo
      results.each { |r| MONGO['raw_exams'].insert r }
    rescue Exception => e
      pp e
      binding.pry
    end
  end
end
