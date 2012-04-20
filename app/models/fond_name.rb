class FondName < ActiveRecord::Base

  extend Cleaner

  belongs_to :fond

  squished_fields :name, :qualifier, :note

end

