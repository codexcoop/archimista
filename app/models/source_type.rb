class SourceType < ActiveRecord::Base

  has_many :sources, :foreign_key => :source_type_code

  named_scope :roots, :conditions => { :parent_code => nil }, :order => "position"
  named_scope :subtypes_of, lambda { |parent_code| {
    :conditions => { :parent_code => parent_code },
    :order => "position" }
  }

end

