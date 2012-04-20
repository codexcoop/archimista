class CreatorIdentifier < ActiveRecord::Base

  extend Cleaner

  belongs_to :creator
  squished_fields :identifier, :identifier_source, :note

end

