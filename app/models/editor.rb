class Editor < ActiveRecord::Base

  belongs_to :updater,  :class_name => "User", :foreign_key => "updated_by"

  # Modules

  extend Cleaner

  # Virtual attributes

  def full_name
    "#{first_name} #{last_name}"
  end

  def reverse_full_name
    "#{last_name}, #{first_name}"
  end

  def value
    full_name
  end

  # Validations

  validates_presence_of :first_name, :last_name
  validates_uniqueness_of :group_id, :scope => [:first_name, :last_name], :case_sensitive => false

  # Callbacks

  squished_fields :first_name, :last_name, :qualifier

  def self.filter
    self.all.collect{|g| [ g.value, g.id ] }.sort
  end

end

