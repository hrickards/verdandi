class Verdandi::Subject < Mongomatic::Base
  def self.all
    parse_find find
  end
end

class Verdandi::BaseSubject < Mongomatic::Base
  def self.all_array
    parse_find find
  end

  def self.find_one_hash(id)
    details = parse_find_hash find_one(BSON::ObjectId(id)).to_hash
  end
end

class Verdandi::SubjectParse 
  NO_CAPITALISE_WORDS = %w{and for of}
  ACRONYMS = {
    'ict' => 'information and communication technology'
  }

  def self.scrape
    BaseSubject.drop
    Subject.drop

    subjects = Exam.all.map { |exam| exam["subject"] }
    base_subjects = subjects.map { |subject| base_subject subject }.uniq.sort

    subjects.map! { |subject| {:name => subject, :base => base_subject(subject) } }.uniq!
    subjects.each { |subject| Subject.insert subject }

    base_subjects.map! { |subject| {:name => subject } }
    base_subjects.each { |base_subject| BaseSubject.insert base_subject }
  end

  protected
  def self.make_subject_hash(subject, count)
    {
      :name => subject,
      :count => count
    }
  end

  def self.properly_capitalise(string)
    string.split(" ").map { |word| NO_CAPITALISE_WORDS.include?(word) ? word.downcase : word.capitalize }.join " "
  end

  def self.replace_acronyms(string)
    string.split(" ").map { |word| ACRONYMS.include?(word) ? ACRONYMS[word] : word }.join " "
  end

  def self.two_way_include(array, string)
    array.inject (false) { |result, object| result or string.include? object }
  end

  def self.base_subject(subject)
    subject = subject.downcase.partition(/[:(]/).first.gsub('&','and').gsub(/applied|studies|first|second|language|modular/, '')
    subject = "science" if two_way_include %w{physics chemistry biology}, subject
    subject.strip!
    subject.lstrip!
    subject = case subject
              when "history of art and design"
                "history"
              when "hospitality and catering"
                "hospitality"
              when "environmental"
                "environmental science"
              when "designtechnologyproducttextiles"
                "design and technology"
              when "economics and business"
                "economics"
              when /^english.*/
                "english"
              when "general"
                "general studies"
              when "leisure"
                "leisure and tourism"
              when "travel and tourism"
                "leisure and tourism"
              when "physical education and sport"
                "physical education"
              when "religious"
                "religious studies"
              when "social science"
                "sociology"
              else
                subject
              end
    subject = replace_acronyms subject
    subject = properly_capitalise subject
  end
end
