class CustodianEditor < ActiveRecord::Base
  belongs_to :custodian
  belongs_to :editor
end

