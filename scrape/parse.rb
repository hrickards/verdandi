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

    Qualification.delete_all
    Qualification.collection.insert specs
  end

  protected
  def unflatten_units(unflattened_units)
    subjects = unflattened_units.map { |u| u[:subject] }.uniq
    subjects.map { |s| {:subject => s, :units => find_units(unflattened_units, s) } }
  end

  def find_units(units, s)
    units.find_all { |u| u[:subject] == s }
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
      @boundaries ||= results.map { |b| [b["year"], b["boundaries"].select { |c| c["code"] == @code }.first] }.map { |year, boundaries| {:season => year, :boundaries => boundaries["grades"], :max_scaled_mark => boundaries["max_scaled_mark"] } }

      one_result = MONGO["raw_boundaries"].find_one('boundaries.code' => @code)
      @qualification ||= one_result['qualification']
      @title ||= one_result["boundaries"].select { |c| c["code"] == @code }.first["title"]
    end
  end

  def get_exams_details
    results = MONGO["raw_exams"].find('exam_code' => @code)
    if results.count > 0
      @exams ||= results.map { |e| {:session => e["session"], :duration => e["duration"], :date => e["date"], :start_time => e["start_time"] } }

      one_result = MONGO["raw_exams"].find_one('exam_code' => @code)
      @qualification ||= parse_qualification one_result['qualification']
      @title ||= one_result['title']
      @awarding_body ||= one_result['awarding_body']
      @subject ||= one_result['subject']
    end
  end

  def generate_unit_hash
    unit_hash = {
      :code => @code,
      :qualification => @qualification,
      :title => @title,
      :boundaries => @boundaries,
      :awarding_body => @awarding_body,
      :subject => @subject,
      :exams => @exams
    }
    unit_hash.delete_if { |k, v| v.nil? or v.empty? }
  end

  protected
  def parse_qualification(qualification)
    QUALIFICATION_MAPPINGS.include?(qualification) ? QUALIFICATION_MAPPINGS[qualification] : qualification
  end
end
