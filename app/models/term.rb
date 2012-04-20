class Term < ActiveRecord::Base
  belongs_to :vocabulary

  # OPTIMIZE: nome poco felice, cambiare
  named_scope :for_select_options, {:joins => :vocabulary,
                                    :select => "terms.*, vocabularies.name AS vocabulary_name",
                                    :order => "vocabularies.name, terms.position"
                                    }

  def self.fond_types
    for_select_options.select {|v| v.vocabulary_name == "fonds.fond_type"}.map(&:term_value)
  end

end

