require 'tree_ext/acts_as_sequence/acts_as_external_sequence/virtual_attributes'
require 'tree_ext/acts_as_sequence/acts_as_external_sequence/manage_sequence'
require 'tree_ext/acts_as_sequence/acts_as_external_sequence/classify'

module TreeExt
  module ActsAsExternalSequence

    include Archimate::ModuleUtils

    attr_accessor :external_parent,
                  :node_name,
                  :order_for_tree_options,
                  :select_for_tree_options,
                  :external_parent_foreign_key

    def acts_as_external_sequence(options={})
      include TreeExt::ActsAsExternalSequence::VirtualAttributes
      include TreeExt::ActsAsExternalSequence::ManageSequence
      extend  TreeExt::ActsAsSequence::ActsAsListScopeBuilder

      # class level instance variables
      initialize_defaults

      # overwrite instance variables with options given in the model
      override_defaults(options)

      named_scope :prepare_external_ordered_nodes, lambda{|structural_parent_ids|
        {
          :select => select_for_tree_options,
          :joins => [external_parent_association_name.to_sym],
          :order => order_for_tree_options,
          :conditions => {external_parent_foreign_key.to_sym => structural_parent_ids}
        }
      }

      # the position is scoped on the acts_as_list scope
      named_scope :prepare_position_by, lambda{|additional_sql_order|
        list_scope_fields_sql = list_scope_fields.map{|field| "#{table_name}.#{field}"}.join(', ')
        order                 = [list_scope_fields_sql, additional_sql_order].join(', ')
        select                = ["DISTINCT #{table_name}.id, #{table_name}.position", list_scope_fields_sql].join(', ')
        {:select => select, :order => order}
      }

      named_scope :external_descendant_nodes_for, lambda{|external_node, options|
        options               = options.blank? ? {} : options
        options[:conditions] ||= {}
        conditions            = merge_conditions(
                                  {external_parent_foreign_key => external_node.subtree_ids},
                                  options.delete(:conditions)
                                )

        { :conditions => conditions }.merge( options )
      }

      #named_scope :additional_conditions, lambda{|conditions| {:conditions => (conditions || {}) } }

      #after_save :update_sequence_for_structural_root
      after_create :insert_in_external_sequence
      after_destroy :update_sequence_for_structural_root, :if => :sequence_number?

    end # acts_as_external_sequence

    def external_parent_foreign_key
      @external_parent_foreign_key ||=  external_parent_association.options[:foreign_key] ||
                                        external_parent.foreign_key
    end

    # TODO: use reflect_on_association, instead
    def external_parent_association
      @external_parent_association ||= reflect_on_all_associations(:belongs_to).find{|ass| ass.class_name == external_parent.to_s.classify}
    end

    def external_parent_association_name
      external_parent_association.name
    end

    def external_parent_class
      @external_parent_class ||= external_parent.to_s.classify.constantize
    end

    private

    def initialize_defaults
      self.node_name = :name
      self.external_parent = nil
      self.order_for_tree_options = nil
      self.select_for_tree_options = nil
    end

    def order_for_tree_options
      @order_for_tree_options ||= " #{external_parent_class.table_name}.ancestry_depth,
                                    #{external_parent_class.table_name}.ancestry,
                                    #{external_parent_class.table_name}.position,
                                    #{table_name}.ancestry_depth,
                                    #{table_name}.ancestry,
                                    #{table_name}.position".squish
    end

    def select_for_tree_options
      @select_for_tree_options ||= "#{table_name}.id,
                                    #{table_name}.ancestry,
                                    #{table_name}.ancestry_depth,
                                    #{table_name}.position,
                                    #{table_name}.#{node_name},
                                    #{table_name}.#{external_parent_foreign_key},
                                    #{table_name}.sequence_number".squish
    end

  end # ActsAsExternalNodes
end

