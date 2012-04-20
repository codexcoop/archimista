class UnitEditor < ActiveRecord::Base
  belongs_to :unit
  belongs_to :editor
end