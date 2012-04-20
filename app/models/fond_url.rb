class FondUrl < ActiveRecord::Base

  extend Cleaner

  belongs_to :fond

  squished_fields :url, :note
  clean_protocol_url :url

end

