class RelCustodianSource < ActiveRecord::Base
  belongs_to :custodian
  belongs_to :source
end

