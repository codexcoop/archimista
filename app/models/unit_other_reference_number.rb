class UnitOtherReferenceNumber < ActiveRecord::Base

  extend Cleaner

  belongs_to :unit

  squished_fields :other_reference_number, :qualifier, :note

end

