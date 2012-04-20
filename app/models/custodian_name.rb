class CustodianName < ActiveRecord::Base

  extend Cleaner

  belongs_to :custodian

  validates_presence_of :name

  squished_fields :name, :qualifier, :note

end

