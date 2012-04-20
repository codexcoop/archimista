class RelCustodianFond < ActiveRecord::Base
  belongs_to :fond
  belongs_to :custodian
end

