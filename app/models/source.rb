class Source < ActiveRecord::Base

  # FIXME: per_page provvisorio per debug plain_misc
  cattr_reader :per_page
  @@per_page = 200

  # Modules
  extend Cleaner

  # Callbacks
  before_save :set_year

  # Associations
  belongs_to :source_type, :primary_key => :code, :foreign_key => :source_type_code
  has_many :source_urls, :dependent => :destroy
  has_many :digital_objects, :as => :attachable, :dependent => :destroy

  # Many-to-many associations (rel)
  # OPTIMIZE: valutare uso di Polymorphic Association. Quali pro/contro ?
  has_many :rel_creator_sources, :dependent => :destroy
  has_many :rel_custodian_sources, :dependent => :destroy
  has_many :rel_fond_sources, :dependent => :destroy
  has_many :rel_unit_sources, :dependent => :destroy

  belongs_to :updater, :class_name => "User", :foreign_key => "updated_by"

  # Nested attributes

  accepts_nested_attributes_for :source_urls,
                                :allow_destroy => true,
                                :reject_if => proc { |a| a['url'].blank? }

  # Validations
  validates_presence_of :source_type_code, :short_title, :title
  # OPTIMIZE: rivedi questa e altre possibili validazioni
  # validates_uniqueness_of :short_title, :on => :create, :message => :taken
  alias_attribute :display_name, :short_title

  # Callbacks
  squished_fields :short_title,
                  :author,
                  :title,
                  :editor,
                  :institution,
                  :publisher,
                  :volume,
                  :pages,
                  :book_title,
                  :date_string

  trimmed_fields :abstract

  def set_year
    if date_string.present?
      self.year = date_string.guess_year
    end
  end

  # Named scopes
  named_scope :autocomplete_list, lambda{|*term|
    term = term.shift
    if term.present?
      conditions = ["LOWER(title) LIKE :term OR LOWER(short_title) LIKE :term", {:term => "%#{term}%"}]
      limit = 10
    else
      conditions = nil
      limit = nil
    end

    {
      :select => "id, author, title, short_title, publisher, year, date_string",
      :conditions => conditions,
      :order => "short_title",
      :limit => limit
    }
  }

  named_scope :search, lambda{|q|
    conditions = ["LOWER(sources.short_title) LIKE :q OR LOWER(sources.title) LIKE :q", {:q => "%#{q.downcase.squish}%"}] if q.present?
    { :conditions => conditions }
  }

end

