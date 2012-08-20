class Verdandi::Exam
  include Mongoid::Document
  store_in collection: 'exams'

  field "title", type: String
  field "code", type: String
  field "subject", type: String
  field "qualification", type: String
  field "awarding_body", type: String
  field "base", type: String
  field "exams", type: Array
  field "sub_units", type: Array
end
