class Qualification
  include Tire::Model::Persistence

  property :id,
           :type => 'integer',
           :index => 'not_analyzed'

  property :subject,
           :type => 'multi_field',
           :fields => {
             :partial_metaphone => {
               :type => 'string',
               :analyzer => 'subject_partial_metaphone'
             },
             :metaphone => {
               :type => 'string',
               :analyzer => 'subject_metaphone'
             },
             :partial => {
               :type => 'string',
               :search_analyzer => 'subject',
               :index_analyzer => 'subject_partial'
             },
             :subject => {
               :type => 'string',
               :analyzer => 'subject'
             }
           }

  property :qualification,
           :type => 'string'

  property :awarding_body,
           :type => "string"

  property :base,
           :type => "string"

  property :units,
           :type => "object"

  settings :analysis => {
    :analyzer => {
      :subject => {
        :type => 'custom',
        :filter => %w{standard lowercase},
        :tokenizer => 'standard'
      },
      :subject_metaphone => {
        :type => 'custom',
        :filter => %w{subject_metaphone},
        :tokenizer => 'standard'
      },
      :subject_partial => {
        :type => 'custom',
        :filter => %w{standard lowercase subject_ngrams},
        :tokenizer => 'standard'
      },
      :subject_partial_metaphone => {
        :type => 'custom',
        :filter => %w{standard lowercase subject_metaphone subject_ngrams},
        :tokenizer => 'standard'
      }
    },

    :filter => {
      :subject_metaphone => {
        :replace => false,
        :encoder => 'metaphone',
        :type => 'phonetic'
      },
      :subject_ngrams => {
        :side => 'front',
        :max_gram => 10,
        :min_gram => 1,
        :type => 'edgeNGram'
      }
    }
  }
end
