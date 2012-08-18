class Qualification
  include Mongoid::Document

  field "subject", type: String
  field "qualification", type: String
  field "awarding_body", type: String
  field "base", type: String
  field "units", type: Array
end
