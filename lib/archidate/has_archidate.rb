require 'archimate/module_utils'
require 'archidate/has_archidate/virtual_attributes'
require 'archidate/has_archidate/callbacks'
require 'archidate/has_archidate/validations'

# extend this module in your entity model, and manage your archidates from your archidatable model
module HasArchidate

    include Archimate::ModuleUtils

    # class level attribute accessors (see: initialize_defaults)
    attr_accessor :events,
                  :archidate_class_name,
                  :cardinality,
                  :events_have_places_when,
                  :events_can_have_places

    alias :events_can_have_places? :events_can_have_places

    # activate archidate capabilities calling this method,
    # after having extended Archimate module
    # options
    #   :events - name of the has_many association (default: "events")
    #   :archidate_class_name - name of the class of the related events (default: "<NameOfEntityClass>Event")
    #   :cardinality (string) - '1' or 'n', (default: '1')
    #   :events_can_have_places - true or false, value of the class-property "events_can_have_places?" (default: false)
    #   :events_have_places_when - symbol representing an instance method, or a
    #     lambda or Proc.new in which the record is made available; if the method/proc
    #     returns true, places for start and end date can be specified; default =>
    #     lambda{|record| false}
    # WARNING: to activate places' elements in the interface and associated validations,
    # both the options :events_can_have_places and :events_have_places_when
    # must return true
    def has_many_archidates(archidatable_options={})

      # class level instance variables
      initialize_defaults

      # overwrite instance variables with options given in the model
      override_defaults(archidatable_options)

      # include modules to gain instance method in the model

      # instance methods
      include HasArchidate::VirtualAttributes
      include HasArchidate::Callbacks
      include HasArchidate::Validations

      # Callbacks
      before_validation :nullify_events_places
      before_validation :set_proper_preferred_event

      # Associations
      has_many events,
        :class_name => archidate_class_name,
        :autosave => true,
        :validate => true,
        :order => 'preferred DESC',
        :dependent => :destroy,
        :inverse_of => :entity

      validates_associated events

      # no validates_associated because the creation and update are always done on the has_many :events association
      has_one :preferred_event,
        :class_name => archidate_class_name,
        :foreign_key => archidate_class_name.to_s.constantize.entity_foreign_key,
        :conditions => {:preferred => true},
        :readonly => true
        # TODO: [Luca] non dovrebbero più servire essendo readonly, verificare ed eliminare
        #:autosave => true,
        #:validate => true,
        #:dependent => :destroy


      validate :at_most_one_preferred_event
      validate :presence_of_preferred_event_if_events_present

      if cardinality == 'n'
        has_many :other_events,
          :class_name => archidate_class_name,
          :foreign_key => archidate_class_name.to_s.constantize.entity_foreign_key,
          :conditions => {:preferred => false},
          :readonly => true
          #:autosave => true,
          #:validate => true,
          #:dependent => :destroy
      end

      # Nested attributes
      accepts_nested_attributes_for events,
        :allow_destroy => true,
        :reject_if => Proc.new{|attrs|
          attrs["start_date_from_year"].to_i  == 0 &&
          attrs["start_century"].to_i         == 0 &&
          attrs["end_date_from_year"].to_i    == 0 &&
          attrs["end_century"].to_i           == 0
        }

      # was:
      #named_scope :with_preferred_event, {
      #  :select => "#{archidate_table}.start_date_display, #{archidate_table}.end_date_display",
      #  :joins => "LEFT OUTER JOIN #{archidate_table} ON #{table_name}.id = #{archidate_table}.#{self.name.foreign_key}",
      #  :conditions => ["#{archidate_table}.preferred = ? OR #{archidate_table}.preferred IS NULL", true]
      #}
      named_scope :with_preferred_event, {
        :select => "#{archidate_table}.start_date_display, #{archidate_table}.end_date_display",
        :joins => sanitize_sql_array([ "LEFT OUTER JOIN #{archidate_table}
                                        ON #{table_name}.id = #{archidate_table}.#{self.name.foreign_key}
                                        AND #{archidate_table}.preferred = ?",  true ])
      }
    end # has_archidate

    def archidate_class
      @archidate_class ||= archidate_class_name.constantize
    end

    def archidate_table
      @archidate_table ||= archidate_class.table_name
    end

    private

    def initialize_defaults
      self.events                   = :events
      self.archidate_class_name     = "#{self.name}Event"
      self.cardinality              = '1' # can be 'n'
      self.events_can_have_places   = false
      self.events_have_places_when  = lambda{|record| false}
    end

end

