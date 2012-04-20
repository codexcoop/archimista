class CreatorLegalStatus < ActiveRecord::Base

  extend Cleaner

  belongs_to :creator
  squished_fields :note

end

