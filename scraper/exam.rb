class Exam
  include Tire::Model::Persistence
  
  property :subject
  property :qualification
  property :awarding_body
  property :base
  property :code
  property :title
  property :sub_units
  property :exams
end
