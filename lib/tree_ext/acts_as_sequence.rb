require 'tree_ext/acts_as_sequence/acts_as_external_sequence'
require 'tree_ext/acts_as_sequence/acts_as_list_scope_builder'
require 'tree_ext/acts_as_sequence/jstree_support'
require 'tree_ext/acts_as_sequence/instance_methods'
require 'tree_ext/acts_as_sequence/maintainance'
require 'tree_ext/acts_as_sequence/manage_sequence'
require 'tree_ext/acts_as_sequence/move'
require 'tree_ext/acts_as_sequence/move_with_sequence'
require 'tree_ext/acts_as_sequence/ordering'
require 'tree_ext/acts_as_sequence/trash'
require 'tree_ext/acts_as_sequence/trash_with_sequence'

module TreeExt
  module ActsAsSequence

    include Archimate::ModuleUtils

    attr_accessor :order_for_tree_options,
                  :select_for_tree_options,
                  :node_name,
                  :external_node_name

    attr_writer   :external_nodes_class

    # Available options:
    # - :node_name
    #   the name of the attribute that represents the name of the node,
    #   the value that will be shown in the web interface;
    #   could be a symbol or a string; default: :name
    # - :external_nodes_class
    #   the model could have a continuation of the tree structure
    #   in some other model, for example Directory could continue in File;
    #   this option lets you specify the external model; default: nil
    # - :external_node_name
    #   same as node_name, but referred to the external_nodes_class; default: :name
    # - :order_for_tree_options
    #   a sql order snippet;
    #   default: "ancestry_depth, ancestry, position"; should not be modified, unless
    #   the model has different columns for these attributes;
    # - :select_for_tree_options
    #   a sql select snippet;
    #   default: "id, sequence_number, ancestry, ancestry_depth, #{node_name}, position, trashed"
    #   same principle applies.
    # Usage:
    #   class Directory < ActiveRecord::Base
    #     extend TreeExt::ActsAsSequence
    #     acts_as_sequence  :external_node_name => 'filename',
    #                       :external_nodes_class => File,
    #                       :node_name => 'dirname'
    #   end
    def acts_as_sequence(options={})
      include TreeExt::ActsAsSequence::InstanceMethods
      include TreeExt::ActsAsSequence::JstreeSupport
      include TreeExt::ActsAsSequence::Maintainance
      include TreeExt::ActsAsSequence::ManageSequence
      include TreeExt::ActsAsSequence::Move
      include TreeExt::ActsAsSequence::MoveWithSequence
      include TreeExt::ActsAsSequence::Ordering
      include TreeExt::ActsAsSequence::Trash
      include TreeExt::ActsAsSequence::TrashWithSequence
      include TreeExt::ActsAsSequence::Utils
      extend  TreeExt::ActsAsSequence::ActsAsListScopeBuilder

      # class level instance variables
      initialize_defaults

      self.order_for_tree_options  = "#{table_name}.ancestry_depth,
                                      #{table_name}.ancestry,
                                      #{table_name}.position".squish

      self.select_for_tree_options = "#{table_name}.id,
                                      #{table_name}.sequence_number,
                                      #{table_name}.ancestry,
                                      #{table_name}.ancestry_depth,
                                      #{table_name}.#{node_name},
                                      #{table_name}.position,
                                      #{table_name}.trashed,
                                      #{table_name}.units_count".squish

      # overwrite class level instance variables with options given in the model
      override_defaults(options)

      if [String, Symbol].include? external_nodes_class
        self.external_nodes_class = external_nodes_class.tableize.classify.constantize
      end

      # Named scopes
      named_scope :order_for_tree, :order => order_for_tree_options
      named_scope :select_for_tree, :select => select_for_tree_options
      named_scope :prepare_ordered_subtree, {
        :order => order_for_tree_options,
        :select => select_for_tree_options
      }
      named_scope :active, :conditions => {:trashed => false}
      named_scope :trashed, :conditions => {:trashed => true}
      named_scope :trashed_roots, :conditions => {:trashed => true, :trashed_ancestor_id => nil}
    end # acts_as_sequence

    def external_nodes_class
      case @external_nodes_class.class
        when Class, NilClass then @external_nodes_class
        when String, Symbol then @external_nodes_class.to_s.classify.constantize
      end
    end

    private

    def initialize_defaults
      self.node_name = :name
      self.external_node_name = :name
      self.external_nodes_class = nil
    end

  end # ActsAsSequence

end

