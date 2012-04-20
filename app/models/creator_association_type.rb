class CreatorAssociationType < ActiveRecord::Base
  has_many :rel_creator_creators
end

