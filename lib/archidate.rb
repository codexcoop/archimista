# encoding: utf-8

require 'archimate/module_utils'
require 'archidate/callbacks'
require 'archidate/validations'
require 'archidate/normalizations'
require 'archidate/virtual_attributes'
require 'archidate/has_archidate'

# extend this module in your model, and gain archidate capabilities
module Archidate

  include Archimate::ModuleUtils

  # class level attribute accessors (see: initialize_defaults)
  attr_accessor :start_date_spec_values,  :start_date_valid_values, :start_date_format_values,
                :end_date_spec_values,    :end_date_valid_values,   :end_date_format_values,
                :specifications, :validities, :formats, :display_fragments,
                :centuries, :century_intervals,
                :default_equal_bounds, :equal_bounds_allowed,
                :entity_class_name, :entity_foreign_key,
                :default_specification_code, :default_validity_code, :default_format_code

  # aliasing query readers
  alias :default_equal_bounds? :default_equal_bounds
  alias :equal_bounds_allowed? :equal_bounds_allowed

  # Activate archidate capabilities calling this method,
  # after having extended Archimate module.
  # Main available options:
  # - :start_date_spec_values, default: ['idem', 'circa', 'post']
  # - :default_specification_code, default: 'idem'
  # - :start_date_valid_values, default: ['C', 'U', 'Q', 'UQ']
  # - :default_validity_code, default: 'C'
  # - :start_date_format_values, default: ['YMD', 'YM', 'Y', 'C']
  # - :default_format_code, default: 'Y'
  # - :end_date_spec_values, default: ['ante', 'idem', 'circa']
  # - :end_date_valid_values, default: ['C', 'U', 'Q', 'UQ']
  # - :end_date_format_values, default: ['YMD', 'YM', 'Y', 'C', 'O', 'U']
  # - :default_equal_bounds, default: false
  # - :equal_bounds_allowed, default: true
  #
  # For all the options above, validations and user interfaces automatically adapt
  # accordingly.
  #
  # Other useful options are:
  # - :entity_class_name
  #   the name of the entity that this type of event belongs to, a String
  #   default: if the event model is UnitEvent, the entity is assumed to be Unit,
  #   unless otherwise specified
  # - :entity_foreign_key
  #   the name of the field which stores the id of the associated entity;
  #   default is the default rails style (entity_class_name#foreign_key)
  # Usage:
  #
  #   class EntityEvent < ActiveRecord::Base
  #     extend Archidate
  #     acts_as_archidate :end_date_format_values => ['YMD', 'YM', 'Y', 'C', 'O']
  #   end
  def acts_as_archidate(archidate_options={})

    # class level instance variables
    initialize_defaults

    # overwrite instance variables with options given in the model
    override_defaults(archidate_options)

    # include modules to gain instance method in the model
    include Archidate::Normalizations
    include Archidate::Callbacks
    include Archidate::Validations
    include Archidate::VirtualAttributes

    # Callbacks

    before_validation :set_start_date,
                      :set_end_date,
                      :set_equal_bounds,
                      :set_end_date_place

    after_validation  :set_start_date_display,
                      :set_end_date_display,
                      :set_order_date
    # Validations

    # TODO: vedere se sia possibile ripristinare la validazione della foreign_key della entity
    #validates_presence_of entity_foreign_key.to_sym # => :creator_id, for example

    validates_presence_of :start_date_spec, :start_date_valid,  :start_date_format

    validates_presence_of :end_date_spec,   :end_date_valid,    :end_date_format,
      :if => lambda{|record|
        record.start_date_from?   &&
        record.start_date_spec?   &&
        record.start_date_valid?  &&
        record.start_date_format?
      }

    # TODO: eliminare quando confermato: le validazioni sono state riportate alla condizione precedente dopo aver aggiornato i default delle date con end_date_format == 'O'
    #validates_presence_of :end_date_spec, :end_date_valid,
    #  :unless => lambda{|record|
    #    record.end_date_format == 'O' # || record.end_date_format.not_in?(end_date_spec_values)
    #  }

    validates_presence_of :start_date_from,
      :if => lambda{|record|
        !record.invalid_start_date?                               &&
        record.start_date_spec?                                   &&
        record.start_date_spec.is_in?(start_date_spec_values)     &&
        record.start_date_valid?                                  &&
        record.start_date_valid.is_in?(start_date_valid_values)   &&
        record.start_date_format?                                 &&
        record.start_date_format.is_in?(start_date_format_values)
      }

    validates_presence_of :end_date_from,
      :if => lambda{|record|
        record.start_date_from?                                       &&
        record.end_date_format?                                       &&
        record.end_date_format.is_in?(end_date_format_values - ['U'])
      }

    # should never occur because automatically generated
    validates_presence_of :start_date_to, :if => :start_date_from?
    validates_presence_of :end_date_to,   :if => :end_date_from?

    validate :numericality_of_start_date_from_year,
      :if => lambda{|record| record.start_date_from_year.present?}
    validate :numericality_of_end_date_from_year,
      :if => lambda{|record| record.end_date_from_year.present? }

    validate :numericality_of_start_century,
      :if => lambda{|record| record.start_century.present?}
    validate :numericality_of_end_century,
      :if => lambda{|record| record.end_century.present?}

    validates_inclusion_of :start_date_format,
      :in => start_date_format_values,
      :if => :start_date_format?

    validates_inclusion_of :start_date_valid,
      :in => start_date_valid_values,
      :if => :start_date_valid?

    validates_inclusion_of :end_date_format,
      :in => end_date_format_values,
      :if => :end_date_format?

    validates_inclusion_of :end_date_valid,
      :in => end_date_valid_values,
      :if => :end_date_valid?

    # should never occur, if the month is in 1..12 and the day in 1..31, because
    # the value is automatically brought to the first valid preceding date
    validate  :add_invalid_start_date_error, :add_invalid_end_date_error

    # this should occur only if the method set_start_date_to is not working as expected
    validate  :start_date_range,
      :if => lambda{|record| record.start_date_from }
    # this should occur only if the method set_end_date_to is not working as expected
    validate  :end_date_range,
      :if => lambda{|record| record.end_date_from }

    validate :start_date_spec_against_date, :if => :start_date_from?

    validate :end_date_spec_against_date,   :if => :end_date_from?

    validate :no_future_start_date, :no_future_end_date

    validate :no_inversion,
      :if =>  lambda{|record|
        record.start_date_from_year_natural?  &&
        record.end_date_from_year_natural?    &&
        record.start_date_from?               &&
        record.start_date_to?                 &&
        record.end_date_from?                 &&
        record.end_date_to?                   &&
        record.not_future_start_date?         &&
        record.not_future_end_date?
      }

    validate :no_intersection,
      :if => lambda{|record|
        record.start_date_from_year_natural?  &&
        record.end_date_from_year_natural?    &&
        record.has_not_inversion?             &&
        record.not_future_start_date?         &&
        record.not_future_end_date?
      }

    # Associations
    belongs_to :entity, :class_name => @entity_class_name, :foreign_key => @entity_foreign_key

    # Named scopes
    named_scope :ordered, {:order => "#{self.table_name}.order_date ASC"}
    named_scope :for_entity, lambda{|entity|
      {:conditions => ["#{self.table_name}.#{entity_foreign_key} = ?", entity.id]}
    }
  end # acts_as_archidate

  # TODO: improve readability
  def specifications_for_select(attr_name, lang)
    ActiveSupport::OrderedHash[
      *specifications.to_a.
          select{|code,desc| send("#{attr_name}_values").include?(code)}.
          map{|code,desc| [((desc[:label] && desc[:label][lang.to_sym]) || desc[:human][lang.to_sym]), code]}.
          flatten(1)
    ]
  end

  def validities_for_select(lang)
    validities.map{|code,desc| [((desc[:label] && desc[:label][lang.to_sym]) || desc[:human][lang.to_sym]), code] }
  end

  def reverted_centuries_for_select(lang)
    centuries.map{|code,desc| [desc[:human][lang.to_sym], code.to_s]}.reverse
  end

  def century_intervals_for_select(lang)
    century_intervals.map{|code,desc| [desc[:human][lang.to_sym], code.to_s]}
  end

  def formats_for(attr_name, lang)
    formats_array = formats.to_a.
                    select{|code,desc| send("#{attr_name}_values").include?(code)}.
                    flatten(1)

    ActiveSupport::OrderedHash[*formats_array]
  end

  def initialize_defaults
    self.entity_class_name = self.name.sub(/Event\Z/,'')

    self.entity_foreign_key = @entity_class_name.foreign_key

    self.specifications = ActiveSupport::OrderedHash[
      'ante' , {:priority => 0, :human => {:it => "ante"}, :display => {:it => "ante"}},
      'idem' , {:priority => 1, :human => {:it => "="}, :display => {:it => ""}},
      'circa', {:priority => 2, :human => {:it => "circa"}, :display => {:it => "circa"}},
      'post' , {:priority => 3, :human => {:it => "post"}, :display => {:it => "post"}}
    ]

    self.validities = ActiveSupport::OrderedHash[
      'C' , {:priority => 0, :human => {:it => "certa"}, :label => {:it => "validità..."}},
      'U' , {:priority => 1, :human => {:it => "incerta"}},
      'Q' , {:priority => 2, :human => {:it => "attribuita"}},
      'UQ', {:priority => 3, :human => {:it => "incerta e attribuita"}}
    ]

    self.formats = ActiveSupport::OrderedHash[
      'Y', {:human => {:it => "data puntuale"}},
      'C', {:human => {:it => "data secolare"}},
      'O', {:human => {:it => "data aperta"}},
      'U', {:human => {:it => "data sconosciuta"}}
    ]

    self.default_specification_code  = 'idem'
    self.default_validity_code       = 'C'
    self.default_format_code         = 'Y'

    self.default_equal_bounds   = false
    self.equal_bounds_allowed   = true

    self.start_date_spec_values   = ['idem', 'circa', 'post']
    self.start_date_valid_values  = ['C', 'U', 'Q', 'UQ']
    self.start_date_format_values = ['YMD', 'YM', 'Y', 'C']
    self.end_date_spec_values     = ['ante', 'idem', 'circa']
    self.end_date_valid_values    = ['C', 'U', 'Q', 'UQ']
    self.end_date_format_values   = ['YMD', 'YM', 'Y', 'C', 'O', 'U']

    self.centuries = ActiveSupport::OrderedHash[
      1,  {:human => {:it => "sec. I"},     :roman => "I"},
      2,  {:human => {:it => "sec. II"},    :roman => "II"},
      3,  {:human => {:it => "sec. III"},   :roman => "III"},
      4,  {:human => {:it => "sec. IV"},    :roman => "IV"},
      5,  {:human => {:it => "sec. V"},     :roman => "V"},
      6,  {:human => {:it => "sec. VI"},    :roman => "VI"},
      7,  {:human => {:it => "sec. VII"},   :roman => "VII"},
      8,  {:human => {:it => "sec. VIII"},  :roman => "VIII"},
      9,  {:human => {:it => "sec. IX"},    :roman => "IX"},
      10, {:human => {:it => "sec. X"},     :roman => "X"},
      11, {:human => {:it => "sec. XI"},    :roman => "XI"},
      12, {:human => {:it => "sec. XII"},   :roman => "XII"},
      13, {:human => {:it => "sec. XIII"},  :roman => "XIII"},
      14, {:human => {:it => "sec. XIV"},   :roman => "XIV"},
      15, {:human => {:it => "sec. XV"},    :roman => "XV"},
      16, {:human => {:it => "sec. XVI"},   :roman => "XVI"},
      17, {:human => {:it => "sec. XVII"},  :roman => "XVII"},
      18, {:human => {:it => "sec. XVIII"}, :roman => "XVIII"},
      19, {:human => {:it => "sec. XIX"},   :roman => "XIX"},
      20, {:human => {:it => "sec. XX"},    :roman => "XX"},
      21, {:human => {:it => "sec. XXI"},   :roman => "XXI"}
    ]

    self.display_fragments = {
      :century => {:human => {:it => "secolo"}, :abbr => {:it => "sec."}}
    }

    self.century_intervals = ActiveSupport::OrderedHash[
      'beginning',      {:range => (1..10),   :human => {:it => "inizio"}},
      'end',            {:range => (91..100), :human => {:it => "fine"}},
      'middle',         {:range => (46..55),  :human => {:it => "metà"}},
      'first_half',     {:range => (1..50),   :human => {:it => "prima metà"}},
      'second_half',    {:range => (51..100), :human => {:it => "seconda metà"}},
      'first_quarter',  {:range => (1..25),   :human => {:it => "primo quarto"}},
      'second_quarter', {:range => (26..50),  :human => {:it => "secondo quarto"}},
      'third_quarter',  {:range => (51..75),  :human => {:it => "terzo quarto"}},
      'last_quarter',   {:range => (76..100), :human => {:it => "ultimo quarto"}}
    ]

  end # initialize_defaults
  private :initialize_defaults

end

