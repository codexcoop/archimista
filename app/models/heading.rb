class Heading < ActiveRecord::Base

  cattr_reader :per_page
  @@per_page = 100

  extend Cleaner

  belongs_to :updater,  :class_name => "User", :foreign_key => "updated_by"

  # Many-to-many associations (rel)

  has_many :rel_unit_headings, :autosave => true, :dependent => :destroy
  has_many :units, :through => :rel_unit_headings

  has_many :rel_fond_headings, :autosave => true, :dependent => :destroy
  has_many :fonds, :through => :rel_fond_headings

  # Validations
  validates_presence_of :name
  validates_uniqueness_of :name, :scope => [:heading_type, :dates, :qualifier, :db_source], :case_sensitive => false

  # Virtual attributes
  def full_string
    [ "[#{heading_type}] " + name, dates, qualifier ].
      delete_if { |fragment| fragment.blank? }.
      join(", ")
  end

  alias_attribute :value, :full_string

  # Callbacks
  squished_fields :name, :dates, :qualifier

  # Named scopes
  # OPTIMIZE: il metodo sembra inutilizzato.
  # Modificarlo in modo che venga usato da azione list o eliminarlo
  named_scope :autocomplete_list, lambda{|*term|
    term = term.shift
    if term.present?
      conditions = ["LOWER(heading_type) LIKE :term
                      OR LOWER(name) LIKE :term
                      OR LOWER(dates) LIKE :term
                      OR LOWER(qualifier) LIKE :term",
        {:term => "%#{term}%"}]
      limit = 20
    else
      conditions = nil
      limit = nil
    end

    {
      :select => "id, heading_type, name, dates, qualifier",
      :conditions => conditions,
      :order => "heading_type, name, dates, qualifier",
      :limit => limit
    }
  }

  def self.find_or_initialize(params)
    self.find_or_initialize_by_name_and_dates_and_qualifier_and_heading_type_and_group_id(params)
  end
end

