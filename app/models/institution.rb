class Institution < ActiveRecord::Base

  extend Cleaner

  validates_presence_of :name

  squished_fields :name
  trimmed_fields :description, :note

  has_many :institution_editors, :dependent => :destroy, :order => :edited_at
  belongs_to :updater,  :class_name => "User", :foreign_key => "updated_by"

  accepts_nested_attributes_for :institution_editors,
    :allow_destroy => true,
    :reject_if => Proc.new { |a| a['name'].blank? }

end

