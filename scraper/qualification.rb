class Qualification
  include Tire::Model::Persistence

  property :subject
  property :id,
           :type => 'integer',
           :index => 'not_analyzed'

  property :qualification,
           :type => 'string'

  property :awarding_body,
           :type => "string"

  property :base,
           :type => "string"

  property :units,
           :type => "object"
end
