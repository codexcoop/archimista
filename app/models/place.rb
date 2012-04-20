class Place < ActiveRecord::Base
  #named_scope :list, :select => "places.id, places.display_name", :limit => 10
  
  named_scope :list, lambda { |field| { :select => "id, #{field} AS value", :limit => 10 }}

  named_scope :by_qualifier, lambda { |qualifier| { :conditions => "qualifier = '#{qualifier}'" }}

  named_scope :search, lambda { |term, field| {:conditions => "lower(#{field}) LIKE '#{term}%'"}}
  
end

