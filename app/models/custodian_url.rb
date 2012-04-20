class CustodianUrl < ActiveRecord::Base

  extend Cleaner

  belongs_to :custodian

  squished_fields :url, :note
  clean_protocol_url :url

end

