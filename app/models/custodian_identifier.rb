class CustodianIdentifier < ActiveRecord::Base

  extend Cleaner

  belongs_to :custodian

  squished_fields :indentifier, :identifier_source, :note

end

