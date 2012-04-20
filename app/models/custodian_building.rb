class CustodianBuilding < ActiveRecord::Base

  extend Cleaner

  belongs_to :custodian

  squished_fields :name, :address, :postcode, :city, :state
  trimmed_fields  :description

end

