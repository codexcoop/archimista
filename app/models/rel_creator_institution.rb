class RelCreatorInstitution < ActiveRecord::Base
  belongs_to :creator
  belongs_to :institution
end

