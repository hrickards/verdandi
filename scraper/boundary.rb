class Verdandi::Boundary
  include Mongoid::Document
  store_in collection: 'boundaries'

  field "title", type: String
  field "code", type: String
  field "subject", type: String
  field "qualification", type: String
  field "awarding_body", type: String
  field "base", type: String
  field "boundaries", type: Array
end
