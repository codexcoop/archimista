class ProjectCredit < ActiveRecord::Base

  extend Cleaner

  belongs_to :project

  squished_fields :credit_name

end

