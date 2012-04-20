class RelFondSource < ActiveRecord::Base
  belongs_to :fond
  belongs_to :source
end

