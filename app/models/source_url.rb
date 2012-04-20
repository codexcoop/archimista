class SourceUrl < ActiveRecord::Base

  extend Cleaner

  belongs_to :source

  squished_fields :url, :note
  clean_protocol_url :url

end

