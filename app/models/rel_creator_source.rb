class RelCreatorSource < ActiveRecord::Base
  belongs_to :creator
  belongs_to :source
end

