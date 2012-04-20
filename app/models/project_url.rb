class ProjectUrl < ActiveRecord::Base

  extend Cleaner

  belongs_to :project

  squished_fields :url, :note
  clean_protocol_url :url

end

