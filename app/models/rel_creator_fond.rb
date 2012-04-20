class RelCreatorFond < ActiveRecord::Base
  belongs_to :fond
  belongs_to :creator
end

