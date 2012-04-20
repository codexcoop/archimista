class Group < ActiveRecord::Base

  extend Cleaner

  before_destroy :is_empty?
  has_many :users

  validates_presence_of :name
  validates_uniqueness_of :name
  squished_fields :name

  def is_empty?
    users.empty?
  end

  def self.filter(group=1)
    case group
    when 1 then
      self.all(:order => :name).map{|g| [ g.name, g.id ] }
    else
      self.all(:conditions => "id = #{group}", :order => :name).map {|g| [ g.name, g.id ] }
    end
  end

end

