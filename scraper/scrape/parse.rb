module Verdandi
  def parse
    boundaries_codes = MONGO["raw_boundaries"].find.map { |r| r["boundaries"].map { |b| b["code"] } }.flatten
    exams_codes = MONGO["raw_exams"].find.map { |e| e["exam_code"] }
    codes = (boundaries_codes + exams_codes).uniq

    flattened_units = codes.map { |code| ParseUnit.new(code).parse }
    # TODO: Make it so we don't need to do this - identify why some boundaries
    # have no exams
    flattened_units.select! { |unit| not (unit[:subject].nil? or unit[:subject].empty?) }

    specs = unflatten_units flattened_units
    specs = specs.map { |spec| parse_specification spec }
    specs = add_id specs

    boundaries = specs.map { |spec| parse_boundaries_from_units spec }.flatten.select { |boundaries| not (boundaries.nil? or boundaries.empty?) }
    boundaries = add_id boundaries

    exams = specs.map { |spec| parse_exams_from_units spec }.flatten.select { |el| not (el.nil? or el.empty?) }
    exams = add_id exams

    Qualification.index.delete
    Boundary.index.delete
    Exam.index.delete
    
    specs.each { |spec| Qualification.create spec }
    boundaries.each { |boundary| Boundary.create boundary }
    exams.each { |exam| Exam.create exam }

    Qualification.index.refresh
    Boundary.index.refresh
    Exam.index.refresh
  end

  protected
  def unflatten_units(unflattened_units)
    subjects = unflattened_units.map { |u| u[:subject] }.uniq
    subjects.map { |s| {:subject => s, :units => find_units(unflattened_units, s) } }
  end

  def find_units(units, s)
    subject_units = units.find_all { |u| u[:subject] == s }

    sub_unit_codes = subject_units.map { |unit| unit[:sub_units].nil? ? [] : unit[:sub_units].map { |su| su[:code] } }.flatten
    subject_units.select { |u| not sub_unit_codes.include?(u[:code]) }
  end

  def parse_specification(spec)
    %w{qualification awarding_body}.each { |s| move_out_of_units spec, s.to_sym }
    spec[:units].map { |unit| unit.delete :subject }
    spec[:base] = MONGO['raw_subjects'].find_one(:name => spec[:subject])["base"]

    spec
  end

  def move_out_of_units(spec, symbol)
    spec[symbol] = spec[:units].first[symbol]
    spec[:units].map { |unit| unit.delete symbol }

    spec.delete symbol unless spec[symbol]
  end

  def parse_boundaries_from_units(spec)
    spec[:units].select { |unit| not (unit[:boundaries].nil? or unit[:boundaries].empty?) or (unit[:sub_units].nil? ? false : unit[:sub_units].any? { |su| not (su[:boundaries].nil? or su[:boundaries].empty?) } ) }.map { |unit| {:subject => spec[:subject], :qualification => spec[:qualification], :awarding_body => spec[:awarding_body], :base => spec[:base], :code => unit[:code], :title => unit[:title], :boundaries => unit[:boundaries], :sub_units => unit[:sub_units].nil? ? [] : unit[:sub_units].map { |su| {:title => su[:title], :code => su[:code], :boundaries => su[:boundaries] } } } }
    #spec[:units].select { |unit| not (unit[:boundaries].nil? or unit[:boundaries].empty?) }.map { |unit| {:subject => spec[:subject], :qualification => spec[:qualification], :awarding_body => spec[:awarding_body], :base => spec[:base], :code => unit[:code], :title => unit[:title], :boundaries => unit[:boundaries] } }
  end

  def parse_exams_from_units(spec)
    spec[:units].select { |unit| not (unit[:exams].nil? or unit[:exams].empty?) or (unit[:sub_units].nil? ? false : unit[:sub_units].any? { |su| not (su[:exams].nil? or su[:exams].empty?) } ) }.map { |unit| {:subject => spec[:subject], :qualification => spec[:qualification], :awarding_body => spec[:awarding_body], :base => spec[:base], :code => unit[:code], :title => unit[:title], :exams => unit[:exams], :sub_units => unit[:sub_units].nil? ? [] : unit[:sub_units].map { |su| {:title => su[:title], :code => su[:code], :exams => su[:exams] } } } }
    #spec[:units].select { |unit| not (unit[:exams].nil? or unit[:exams].empty?) }.map { |unit| {:subject => spec[:subject], :qualification => spec[:qualification], :awarding_body => spec[:awarding_body], :base => spec[:base], :code => unit[:code], :title => unit[:title], :exams => unit[:exams] } }
  end

  def add_id(elements)
    elements.each_with_index.map { |el, i| el.merge({:id => i}) }
  end
end

class Verdandi::ParseUnit
  QUALIFICATION_MAPPINGS = {
    "GCE" => :a_level
  }

  def initialize(code)
    @code = code
  end

  def parse
    get_boundaries_details
    get_exams_details

    generate_unit_hash
  end

  def get_boundaries_details
    results = MONGO["raw_boundaries"].find('boundaries.code' => @code)
    if results.count > 0
      right_results = results.map { |b| [b["year"], b["boundaries"].select { |c| c["code"] == @code }.first] }

      su_results = right_results.select { |y, b| not (b["sub_units"].nil? or b["sub_units"].empty?) }
      if su_results.empty?
        @sub_units = []
      else
        su_codes = su_results.map { |y, b| b["sub_units"].map { |su| su["code"] } }.flatten.uniq
        @sub_units = su_codes.map { |code| su_results.map { |y, b| [y, b["sub_units"].select { |su| su["code"] == code }] }.select { |d, e| not (e.nil? or e.empty?) } }.map { |su| { :title => su[0][1][0]["title"], :code => su[0][1][0]["code"], :boundaries => su.map { |suu| {:season => parse_boundary_season(suu[0]), :max_scaled_mark => suu[1][0]["max_scaled_mark"], :boundaries => suu[1][0]["grades"] } } } }
      end

      @boundaries = right_results.map { |year, boundaries| {:season => parse_boundary_season(year), :boundaries => boundaries["grades"], :max_scaled_mark => boundaries["max_scaled_mark"] } }

      one_result = MONGO["raw_boundaries"].find_one('boundaries.code' => @code)
      @qualification ||= one_result['qualification']
      @title ||= one_result["boundaries"].select { |c| c["code"] == @code }.first["title"]
    end
  end

  def get_exams_details
    results = MONGO["raw_exams"].find('exam_code' => @code)
    if results.count > 0
      @exams ||= results.map { |e| {:season => parse_exam_season(e["session"]), :duration => e["duration"], :date => e["date"], :start_time => e["start_time"] } }

      one_result = MONGO["raw_exams"].find_one('exam_code' => @code)
      @qualification ||= parse_qualification one_result['qualification']
      @title ||= one_result['title']
      @awarding_body ||= one_result['awarding_body']
      @subject ||= one_result['subject']
    end

    @sub_units.map! { |unit| add_sub_unit_exams_details unit } unless @sub_units.nil?
  end

  def generate_unit_hash
    unit_hash = {
      :code => @code,
      :qualification => @qualification,
      :title => @title,
      :boundaries => @boundaries,
      :awarding_body => @awarding_body,
      :sub_units => @sub_units,
      :subject => @subject,
      :exams => @exams
    }
    unit_hash.delete_if { |k, v| v.nil? or v.empty? }
  end

  protected
  def parse_qualification(qualification)
    QUALIFICATION_MAPPINGS.include?(qualification) ? QUALIFICATION_MAPPINGS[qualification] : qualification
  end

  def add_sub_unit_exams_details(unit)
    results = MONGO["raw_exams"].find('exam_code' => unit[:code])
    if results.count > 0
      unit[:exams] = results.map { |e| {:season => parse_exam_season(e["session"]), :duration => e["duration"], :date => e["date"], :start_time => e["start_time"] } } 
      @subject ||= MONGO["raw_exams"].find_one('exam_code' => unit[:code])['subject']
    end

    unit
  end

  def parse_exam_season(season)
    season.scan(/([\w\s]*)( \[\w*\])?/)[0][0].strip
  end

  def parse_boundary_season(season)
    season.to_s.gsub("_", " ").capitalize.gsub(/(June)|(July)/, "Summer")
  end
end
