class CreatorActivity < ActiveRecord::Base

  extend Cleaner

  belongs_to :creator
  squished_fields :activity, :note

end

