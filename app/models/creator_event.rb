class CreatorEvent < ActiveRecord::Base

  extend Archidate

  acts_as_archidate :end_date_format_values => ['YMD', 'YM', 'Y', 'C', 'O'],
                    :equal_bounds_allowed   => false

end

