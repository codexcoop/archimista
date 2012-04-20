class CreatorName < ActiveRecord::Base

  attr_accessor :creator_type, :note_p, :note_cf

  extend Cleaner

  belongs_to :creator

  validates_presence_of :name
  validates_presence_of :first_name, :last_name, :if => Proc.new { |a| a.creator_type == "P" }

  squished_fields :name, :first_name, :last_name, :note, :qualifier

end

