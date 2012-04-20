class DocumentFormEditor < ActiveRecord::Base
  belongs_to :document_form
  belongs_to :editor
end

