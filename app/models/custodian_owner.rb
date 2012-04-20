class CustodianOwner < ActiveRecord::Base

  extend Cleaner

  belongs_to :custodian

  squished_fields :owner

end

