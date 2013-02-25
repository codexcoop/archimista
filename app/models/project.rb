class Project < ActiveRecord::Base
  # Modules

  extend Cleaner

  # Associations
  belongs_to :updater,  :class_name => "User", :foreign_key => "updated_by"
  has_one :import, :as => :importable, :dependent => :destroy

  has_many  :project_credits, :dependent => :destroy
  has_many  :project_urls, :dependent => :destroy
  has_many  :project_managers, :class_name => 'ProjectCredit', :conditions => {:credit_type => 'PM'}
  has_many  :project_stakeholders, :class_name => 'ProjectCredit', :conditions => {:credit_type => 'PS'}

  # Many-to-many associations (rel)

  has_many :rel_project_fonds, :dependent => :destroy, :autosave => true
  has_many :fonds, :through => :rel_project_fonds,
           :include => :preferred_event, :order => "fonds.name"

  # Nested attributes

  accepts_nested_attributes_for :project_urls,
                                :allow_destroy => true,
                                :reject_if => proc { |a| a['url'].blank? }

  accepts_nested_attributes_for :project_credits,
                                :allow_destroy => true,
                                :reject_if => proc { |a| a['credit_name'].blank? }

  accepts_nested_attributes_for :project_managers,
                                :allow_destroy => true,
                                :reject_if => proc { |a| a['credit_name'].blank? }

  accepts_nested_attributes_for :project_stakeholders,
                                :allow_destroy => true,
                                :reject_if => proc { |a| a['credit_name'].blank? }

  accepts_nested_attributes_for :rel_project_fonds,
                                :allow_destroy => true,
                                :reject_if => Proc.new { |a| a['fond_id'].blank? }

  # Named scopes

  named_scope :autocomplete_list, lambda{|term|
    {
      :select => "id, name, name AS value",
      :conditions => ["LOWER(name) LIKE ?", "%#{term.downcase.squish}%"],
      :order => "name ASC",
      :limit => 10
    }
  }

  named_scope :export_list, :select => "projects.id, projects.name, projects.updated_at, count(projects.id) AS num",
              :joins => [:fonds],
              :group => "projects.id",
              :order => "projects.name"

  # Callbacks

  squished_fields :name
  trimmed_fields :description, :note

  # Validations

  validates_presence_of :name
  validate :end_year_greater_than_start_year

  # Virtual attributes
  alias_attribute :display_name, :name
  
  public

  def display_date
    if start_year == end_year
      "#{start_year.to_s}"
    else
      "#{start_year.to_s}-#{end_year.to_s}"
    end
  end

  # TODO: dry
  def sorted_rel_project_fonds
    rel_project_fonds.all(:include => :fond).sort_by{|rel| rel.fond.try(:name) || 'zz'}
  end

  private

  def end_year_greater_than_start_year
    unless self.end_year >= self.start_year
      errors.add(:start_year, "should be prior to the end date")
      errors.add(:end_year, "should be greater than end date")
    end
  end

end

