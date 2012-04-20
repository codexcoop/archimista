# encoding: utf-8

require 'unit_support/class_methods'

module UnitSupport

  # NOTE: Il modulo contiene sia metodi specifici di JqGrid sia metodi generici di bulk creation e deletion.

  # class level instance attributes, see initialize_defaults
  attr_accessor :joins_for_grid,
                :columns_to_search,
                :terms_for_select_options,
                :vocabularies_with_terms

  def activate_unit_support
    extend UnitSupport::ClassMethods

    initialize_defaults
    # placeholder: include modules to gain instance methods in the model
  end

  # class level instance attributes
  def initialize_defaults

    self.joins_for_grid = "
      INNER JOIN fonds ON units.fond_id = fonds.id
      LEFT OUTER JOIN unit_events ON units.id = unit_events.unit_id
    ".squish

    self.columns_to_search = column_names - ['id', 'fond_id', 'fond_name']

    self.terms_for_select_options = Term.for_select_options

    self.vocabularies_with_terms = vocabularies_for_grid(terms_for_select_options)

  end

end

