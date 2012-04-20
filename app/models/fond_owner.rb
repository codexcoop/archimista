class FondOwner < ActiveRecord::Base

  extend Cleaner

  belongs_to :fond

  squished_fields :owner

end

