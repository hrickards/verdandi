class Boundary
  include Mongoid::Document

  field "title", type: String
  field "code", type: String
  field "subject", type: String
  field "qualification", type: String
  field "awarding_body", type: String
  field "base", type: String
  field "boundaries", type: Array
end
