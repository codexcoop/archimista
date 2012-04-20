class Fond < ActiveRecord::Base

  # Modules

  extend Cleaner

  # Callbacks

  before_validation :compact_langs
  before_save :cache_depth # force ancestry_depth update during move operations

  # Associations and custom modules

  include TreeExt::Debug

  extend HasArchidate
  has_many_archidates

  has_ancestry :cache_depth => true

  # Provides the method Fond.save_a_tree(template) - with position and sequence_number
  extend TreeExt::Template
  tree_template_markers :level => '#', :name => '#', :fond_type => '@'

  extend TreeExt::ActsAsSequence
  acts_as_sequence  :external_node_name => 'title',
    :external_nodes_class => Unit

  list_scope_fields :ancestry
  acts_as_list :scope => list_scope

  belongs_to :import, :primary_key => :identifier, :foreign_key => :db_source, :dependent => :destroy
  belongs_to :updater,  :class_name => "User", :foreign_key => "updated_by"

  has_many :fond_names, :dependent => :destroy
  has_many :other_names, :class_name => 'FondName', :conditions => {:qualifier => 'O'}

  has_many :fond_editors, :dependent => :destroy, :order => :edited_at
  has_many :fond_identifiers, :dependent => :destroy
  has_many :fond_langs, :dependent => :destroy
  has_many :fond_owners, :dependent => :destroy
  has_many :fond_urls, :dependent => :destroy

  # OPTIMIZE nella grid c'è un doppio ordinamento per sequence_number
  has_many :units, :dependent => :destroy, :order => "units.sequence_number"
  has_many :descendant_units, :class_name => "Unit", :foreign_key => :root_fond_id, :readonly => true

  def active_descendant_units_count
    Unit.count("id", :joins => :fond, :conditions => {:fond_id => subtree_ids, :fonds => {:trashed => false}})
  end

  has_many :digital_objects, :as => :attachable, :dependent => :destroy

  # Many-to-many associations (rel)

  has_many :rel_custodian_fonds, :autosave => true, :dependent => :destroy
  has_many :custodians, :through => :rel_custodian_fonds

  has_many :rel_creator_fonds, :autosave => true, :dependent => :destroy
  has_many :creators, :through => :rel_creator_fonds

  has_many :rel_project_fonds, :autosave => true, :dependent => :destroy
  has_many :projects, :through => :rel_project_fonds

  has_many :rel_fond_document_forms, :autosave => true, :dependent => :destroy
  has_many :document_forms, :through => :rel_fond_document_forms,
    :order => "document_forms.name"

  has_many :rel_fond_sources, :autosave => true, :dependent => :destroy
  has_many :sources, :through => :rel_fond_sources

  has_many :rel_fond_headings, :autosave => true, :dependent => :destroy
  has_many :headings, :through => :rel_fond_headings

  # Nested attributes

  accepts_nested_attributes_for :fond_names,
    :allow_destroy => true,
    :reject_if => Proc.new { |a| a['qualifier'].blank? || a['name'].blank? }

  accepts_nested_attributes_for :other_names,
    :allow_destroy => true,
    :reject_if => Proc.new { |a| a['qualifier'].blank? || a['name'].blank? }

  accepts_nested_attributes_for :fond_editors,
    :allow_destroy => true,
    :reject_if => Proc.new { |a| a['name'].blank? }

  accepts_nested_attributes_for :fond_identifiers,
    :allow_destroy => true,
    :reject_if => Proc.new { |a| a['identifier'].blank? || a['identifier_source'].blank? }

  accepts_nested_attributes_for :fond_langs,
    :allow_destroy => true,
    :reject_if => Proc.new { |a| a['code'].blank? }

  accepts_nested_attributes_for :fond_owners,
    :allow_destroy => true,
    :reject_if => Proc.new { |a| a['owner'].blank? }

  accepts_nested_attributes_for :fond_urls,
    :allow_destroy => true,
    :reject_if => Proc.new { |a| a['url'].blank? }

  accepts_nested_attributes_for :rel_creator_fonds,
    :allow_destroy => true,
    :reject_if => Proc.new { |a| a['creator_id'].blank? }

  accepts_nested_attributes_for :rel_custodian_fonds,
    :allow_destroy => true,
    :reject_if => Proc.new { |a| a['custodian_id'].blank? }

  accepts_nested_attributes_for :rel_project_fonds,
    :allow_destroy => true,
    :reject_if => Proc.new { |a| a['project_id'].blank? }

  accepts_nested_attributes_for :rel_fond_document_forms,
    :allow_destroy => true,
    :reject_if => Proc.new { |a| a['document_form_id'].blank? }

  accepts_nested_attributes_for :rel_fond_sources,
    :allow_destroy => true,
    :reject_if => Proc.new { |a| a['source_id'].blank? }

  accepts_nested_attributes_for :rel_fond_headings,
    :allow_destroy => true,
    :reject_if => Proc.new { |a| a['heading_id'].blank? }

  # Validations

  validates_presence_of :name
  validates_inclusion_of :fond_type, :in => Term.fond_types, :allow_blank => true
  validates_numericality_of :length, :allow_blank => true, :greater_than => 0
  validate :at_most_one_custodian

  # Callbacks

  blank_default :name
  remove_blank_other_names

  squished_fields :name
  trimmed_fields :fond_type,
    :abstract,
    :description,
    :history,
    :arrangement_note,
    :related_materials,
    :access_condition_note,
    :use_condition_note,
    :preservation_note,
    :note

  # Scopes

  named_scope :list,
    :select => "id, name, units_count, fond_type, updated_at"

  named_scope :default_order, {:order => "fonds.name"}

  named_scope :search, lambda{|q|
    conditions = ["LOWER(fonds.name) LIKE :q", {:q => "%#{q.downcase.squish}%"}] if q.present?
    { :conditions => conditions }
  }

  named_scope :unassigned_to_custodian, lambda { |*args|
    opts      = args.shift
    custodian = opts.respond_to?(:'[]') && opts[:unless]

    conditions = if custodian && custodian.id
      ["rel_custodian_fonds.fond_id IS NULL OR rel_custodian_fonds.custodian_id = ?", custodian.id]
    else
      "rel_custodian_fonds.fond_id IS NULL"
    end
    { :joins => "LEFT OUTER JOIN rel_custodian_fonds ON fonds.id = rel_custodian_fonds.fond_id",
      :conditions => conditions }
  }

  # Virtual attributes

  def active?
    !trashed
  end

  def excluded_creator_ids
    creator_ids || root.creator_ids
  end

  # OPTIMIZE: rinominare in display_name_with_date (usato da relations)
  def name_with_preferred_date
    return unless name.present?
    preferred_event ? "#{h name} (#{preferred_event.full_display_date})" : name
  end

  alias_attribute :display_name, :name
  alias_attribute :value, :name_with_preferred_date

  def sorted_rel_creator_fonds
    rel_creator_fonds.all(:include => {:creator => [:preferred_name, :preferred_event]}).
      sort_by{|rel| rel.creator.try(:preferred_name).try(:name) || 'zz'}
  end

  def sorted_rel_custodian_fonds
    rel_custodian_fonds.all(:include => {:custodian => :preferred_name}).
      sort_by{|rel| rel.custodian.try(:preferred_name).try(:name) || 'zz'}
  end

  def sorted_rel_project_fonds
    rel_project_fonds.all(:include => :project).
      sort_by{|rel| rel.project.try(:name) || 'zz'}
  end

  def sorted_rel_fond_document_forms
    rel_fond_document_forms.all(:include => :document_form).
      sort_by{|rel| rel.document_form.try(:name) || 'zz'}
  end

  def sorted_rel_fond_sources
    rel_fond_sources.all(:include => :source).
      sort_by{|rel| rel.source.try(:short_title) || 'zz'}
  end

  def sorted_rel_fond_headings
    rel_fond_headings.all(:include => :heading).sort_by{|rel| rel.heading.try(:name) || 'zz'}
  end

  # Grid support: bulk creation of units

  attr_accessor :go_to_unit

  # Methods

  def path_items(depth=0)
    path.from_depth(depth).all(:select => "id, name, ancestry")
  end

  def update_deletable_status
    if import
      import.deletable = false
      import.save!
    end
  end

  private

  def compact_langs
    fond_langs.delete_if do |i|
      fond_langs.take(fond_langs.index(i)).any?{|e| e.code == i.code}
    end
  end

  def at_most_one_custodian
    # Warning: rel_custodian_fonds.count would return only the persisted records,
    # while rel_custodian_fonds.size makes the same query (SELECT COUNT) but
    # returns both new records and persisted records.
    # rel_custodian_fonds.length is not a proper solution because make a
    # SELECT * and computes the size on the resulting array
    rel_custodian_fonds_size = rel_custodian_fonds.size - rel_custodian_fonds.select{|rec| rec.marked_for_destruction?}.size
    errors.add_to_base :at_most_one_custodian if rel_custodian_fonds_size > 1
  end

end

