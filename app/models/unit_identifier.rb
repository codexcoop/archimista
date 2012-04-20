class UnitIdentifier < ActiveRecord::Base

  extend Cleaner

  belongs_to :unit

  squished_fields :identifier, :identifier_source, :note

end

