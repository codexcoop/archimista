class FondEditor < ActiveRecord::Base
  belongs_to :fond
  belongs_to :editor
end

