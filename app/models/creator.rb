class Creator < ActiveRecord::Base

  before_validation :reset_associated_records_by_creator_type

  def is_person?
    creator_type == 'P'
  end

  def is_family?
    creator_type == 'F'
  end

  def is_corporate?
    creator_type == "C"
  end

  # Modules

  extend Cleaner
  extend HasArchidate

  has_many_archidates :events_can_have_places => true,
                      :events_have_places_when => :is_person?

  # Associations

  belongs_to :creator_corporate_type
  belongs_to :updater,  :class_name => "User", :foreign_key => "updated_by"

  has_many :creator_names, :dependent => :destroy
  has_one  :preferred_name, :class_name => 'CreatorName', :conditions => {:qualifier => 'A', :preferred => true}
  has_many :other_names, :class_name => 'CreatorName', :conditions => {:preferred => false}

  has_many :creator_legal_statuses, :dependent => :destroy
  has_many :creator_urls, :dependent => :destroy
  has_many :creator_identifiers, :dependent => :destroy
  has_many :creator_activities, :dependent => :destroy
  has_many :creator_editors, :dependent => :destroy, :order => :edited_at

  has_many :digital_objects, :as => :attachable, :dependent => :destroy

  # Many-to-many associations (rel)

  has_many :rel_creator_creators, :dependent => :destroy, :autosave => true
  has_many :related_creators, :through => :rel_creator_creators

  has_many :inverse_rel_creator_creators, :class_name => "RelCreatorCreator", :foreign_key => "related_creator_id"
  has_many :inverse_related_creators, :through => :inverse_rel_creator_creators, :source => :creator

  has_many :rel_creator_fonds, :dependent => :destroy, :autosave => true
  has_many :fonds, :through => :rel_creator_fonds, :include => :preferred_event, :order => "fonds.name"

  has_many :rel_creator_institutions, :dependent => :destroy, :autosave => true
  has_many :institutions, :through => :rel_creator_institutions

  has_many :rel_creator_sources, :dependent => :destroy, :autosave => true
  has_many :sources, :through => :rel_creator_sources

  # Nested attributes

  accepts_nested_attributes_for :creator_names,
                                :allow_destroy => true,
                                :reject_if => proc { |a| a['name'].blank? }

  accepts_nested_attributes_for :preferred_name,
                                :allow_destroy => true,
                                :reject_if => proc { |a| a['preferred'].blank?}

  accepts_nested_attributes_for :other_names,
                                :allow_destroy => true,
                                :reject_if => proc { |a| a['name'].blank? || a['qualifier'].blank? }

  accepts_nested_attributes_for :creator_legal_statuses,
                                :allow_destroy => true,
                                :reject_if => proc { |a| a['legal_status'].blank? }

  accepts_nested_attributes_for :creator_urls,
                                :allow_destroy => true,
                                :reject_if => proc { |a| a['url'].blank? }

  accepts_nested_attributes_for :creator_identifiers,
                                :allow_destroy => true,
                                :reject_if => proc { |a| a['identifier'].blank? || a['identifier_source'].blank? }

  accepts_nested_attributes_for :creator_activities,
                                :allow_destroy => true,
                                :reject_if => proc { |a| a['activity'].blank? }

  accepts_nested_attributes_for :creator_editors,
                                :allow_destroy => true,
                                :reject_if => Proc.new { |a| a['name'].blank? }

  accepts_nested_attributes_for :rel_creator_fonds,
                                :allow_destroy => true,
                                :reject_if => Proc.new { |a| a['fond_id'].blank? }

  accepts_nested_attributes_for :rel_creator_institutions,
                                :allow_destroy => true,
                                :reject_if => Proc.new { |a| a['institution_id'].blank? }

  accepts_nested_attributes_for :rel_creator_creators,
                                :allow_destroy => true,
                                :reject_if => Proc.new { |a| a['related_creator_id'].blank? }

  accepts_nested_attributes_for :rel_creator_sources,
                                :allow_destroy => true,
                                :reject_if => Proc.new { |a| a['source_id'].blank? }
  # Validations

  validates_presence_of :creator_type
  validates_associated :preferred_name

  # Callbacks

  squished_fields :residence
  trimmed_fields  :abstract, :history, :note
  remove_blank_other_names

  # Scopes

  named_scope :list, :select => "creators.id, creators.creator_type, creator_names.name, creators.residence, creators.updated_at",
                     :joins => :preferred_name

  named_scope :search, lambda{|q|
    conditions = ["creator_names.qualifier = 'A' AND LOWER(creator_names.name) LIKE :q", {:q => "%#{q.downcase.squish}%"}] if q.present?
    { :conditions => conditions }
  }

  named_scope :autocomplete_list, lambda{|*term|
    term = term.shift.to_s
    conditions    = ["creator_names.preferred = ?
                      AND creator_names.qualifier = ?
                      AND LOWER(creator_names.name) LIKE ?".squish,
                      true, 'A', "%#{term.downcase.squish}%"]
    {
      :select => "creators.id, creator_names.name",
      :joins => :creator_names,
      :include => :preferred_event,
      :conditions => conditions,
      :order => "creator_names.name ASC",
      :limit => 10
    }
  }

  # Virtual attributes

  def display_name
    preferred_name.name
  end

  # OPTIMIZE: rinominare in display_name_with_date (usato da relations)
  def name_with_preferred_date
    return unless preferred_name
    preferred_event ? "#{h preferred_name.name} (#{preferred_event.full_display_date})" : preferred_name.name
  end

  alias_attribute :value, :name_with_preferred_date

  # Custom validations and methods

  private

  def reset_associated_records_by_creator_type
    # legal status / creator_corporate_type_id
    unless is_corporate?
      self.creator_corporate_type_id = nil
      self.residence = nil
      self.creator_legal_statuses.clear
      self.rel_creator_institutions.clear
    end

    # preferred_names
    if is_person?
      preferred_name.creator_type = "P"
      preferred_name.name = [preferred_name.last_name.squish, preferred_name.first_name.squish].reject(&:blank?).join(", ")
      preferred_name.note_cf = nil
      preferred_name.note = preferred_name.note_p
    else
      preferred_name.creator_type = nil
      preferred_name.first_name = nil
      preferred_name.last_name = nil
      preferred_name.note_p = nil
      preferred_name.note = preferred_name.note_cf
    end
  end

  public

  def self.sorted_suggested
     all(:select => 'creators.id', :include => [:preferred_name, :preferred_event]).
    sort_by{|creator| creator.try(:preferred_name).try(:name)}
  end

  def sorted_rel_creator_fonds
    rel_creator_fonds.all(:include => :fond).sort_by{|rel| rel.fond.try(:name) || 'zz'}
  end

  def sorted_rel_creator_institutions
    rel_creator_institutions.all(:include => :institution).sort_by{|rel| rel.institution.try(:name) || 'zz'}
  end

  def sorted_rel_creator_creators
    rel_creator_creators.all(:include => :creator).sort_by{|rel| rel.creator.preferred_name.try(:name) || 'zz'}
  end

  def sorted_rel_creator_sources
    rel_creator_sources.all(:include => :source).sort_by{|rel| rel.source.try(:short_title) || 'zz'}
  end

end

