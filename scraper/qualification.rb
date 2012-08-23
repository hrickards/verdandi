class Qualification
  include Tire::Model::Persistence

  property :subject
  property :qualification
  property :awarding_body
  property :base
  property :units
  property :id,
           :type => 'integer',
           :index => 'not_analyzed'
end
