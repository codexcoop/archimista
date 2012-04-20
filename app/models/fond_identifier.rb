class FondIdentifier < ActiveRecord::Base

  extend Cleaner

  belongs_to :fond

  squished_fields :identifier, :identifier_source, :note

end

