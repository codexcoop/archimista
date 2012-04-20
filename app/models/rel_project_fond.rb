class RelProjectFond < ActiveRecord::Base
  belongs_to :fond
  belongs_to :project
end

