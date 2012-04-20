class UnitEvent < ActiveRecord::Base

  extend Archidate

  acts_as_archidate :default_equal_bounds => true

end

