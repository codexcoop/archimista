class CreatorUrl < ActiveRecord::Base

  extend Cleaner

  belongs_to :creator

  squished_fields :url, :note
  clean_protocol_url :url

end

