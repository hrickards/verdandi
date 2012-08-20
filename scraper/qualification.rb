class Verdandi::Qualification
  include Mongoid::Document
  store_in collection: 'qualifications'

  field "subject", type: String
  field "qualification", type: String
  field "awarding_body", type: String
  field "base", type: String
  field "units", type: Array
end
