class UnitUrl < ActiveRecord::Base

  extend Cleaner

  belongs_to :unit

  squished_fields :url, :note
  clean_protocol_url :url

end

