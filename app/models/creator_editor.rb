class CreatorEditor < ActiveRecord::Base
  belongs_to :creator
  belongs_to :editor
end

