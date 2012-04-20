class RelFondDocumentForm < ActiveRecord::Base
  belongs_to :fond
  belongs_to :document_form
end

