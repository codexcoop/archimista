class CustodianContact < ActiveRecord::Base

  extend Cleaner

  belongs_to :custodian

  squished_fields :contact, :contact_note
  clean_protocol_url :contact, :if => lambda{|record| record.contact_type == 'web'}

end

