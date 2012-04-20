require 'tree_ext/acts_as_sequence/utils'

module TreeExt
  module ActsAsSequence
    module Ordering

      attr_accessor :memoized_global_position

      # Recreate the order of the tree, using only parent/child (ancestry) relations and positions
      #
      # The subtree:
      # - must be a single consistent tree
      # - must be sorted by ancestry_depth AND ancestry AND position: the algorithm
      #   is optimized to iterate the least possible times over the arrays of ids,
      #   essentially one or two times per method-execution, depending on chosen options;
      #   this way, the ids can be arranged by bulks of siblings, and not individually,
      #   decreasing of an order of magnitude the time required for the ordering
      #   of large trees;
      #   to do that, though, the ids have to be ordered by all the 3 fields, in the specified order,
      #   with all the siblings sequentially ordered; this can be efficiently done by
      #   database itself, demanding the least possible of computation to Ruby
      #
      # - Step 1 (grouped_ids):
      # Collecting ids, grouped by parent_id; each group is a pair, (parent_id, child_ids)
      # could be an OrderedHash (or a Hash in ruby1.9), but not necessary,
      # it is later scanned sequentially.
      # The keys are all the parent, of all levels, the groups are all leafs.
      # - Step 2 (list):
      # Starting to collect the ids in the final order.
      # Being the argument correctly ordered, the first element is the root of the tree
      # Find the position in the list for each parent of the groups,
      # and append the child ids (leafs) after it
      # - Step 3 (sort_by_list):
      # Replace the ids in the ordered list with the actual objects
      #
      # Inspired by arrangeAsList() method by Stefan Kroes.
      def flat_ordered_subtree(opts={})
        prepared_subtree  = if opts[:active_only]
                              subtree.prepare_ordered_subtree.active
                            else
                              subtree.prepare_ordered_subtree
                            end
        grouped_ids       = break_groups_by_key(prepared_subtree, :key => 'parent_id', :attr => 'id')
        list              = if prepared_subtree.size == 1
                              [prepared_subtree.first.id]
                            else
                              nest_groups_by_key(grouped_ids)
                            end

        return list if opts[:ids_only]

        sort_by_list(prepared_subtree, list, :key => 'id') do |node, index|
          node.memoized_global_position = (index+1)
        end
      end

      # Recreate the order of the external tree, using only parent/child (ancestry) relations
      # and positions, both in its own nodes, and the external nodes.
      #
      # The process is mostly the same as the one for a real tree,
      # but these are dependent nodes, and form a fake tree.
      # Main differences:
      # - most nodes have no parent, the parent is assumed the object they belong to;
      #   in this case a fake parent id is included in the list, and marked with "F";
      #   later, of course, these ids are removed from the final list
      # - there is no root, so the groups array must be seeded
      #   with the first structural_parent_id
      def flat_ordered_external_nodes(opts={})
        structural_parent_ids = flat_ordered_subtree(:ids_only => true, :active_only => opts[:active_only])
        prepared_nodes        = external_nodes_class.prepare_external_ordered_nodes(structural_parent_ids)

        return [] if prepared_nodes.blank?

        structural_parent_ids.map!{|id| "F#{id}"} # mark ids as foreign

        grouped_ids = break_groups_by_key(prepared_nodes, :key => 'structural_parent_id', :attr => 'id', :seed  => true)

        list =  if prepared_nodes.size == 1
                  [prepared_nodes.first.id]
                else
                  nest_groups_by_key(grouped_ids, structural_parent_ids).delete_if{|id| id =~ /^F/ }
                end

        return list if opts[:ids_only]

        sort_by_list(prepared_nodes, list, :key => 'id') do |node, index|
          node.memoized_global_position = (index+1)
        end
      end

      # Recreate the order of the tree for a just moved node, using only
      # parent/child (ancestry) relations and sequence_number.
      # Can be used only in moving operations.
      def rearranged_tree_ids_for_moved_node
        other_ordered_active_node_ids.insert(new_index_in_sequence, ordered_active_subtree_ids).flatten!(1)
      end

      # Applicable only to collection of external nodes where all of them already
      # have a significant sequence_number, relatively to their structural parent
      def rearranged_external_node_ids
        external_nodes =  external_nodes_class.
                          find(:all,
                            :joins => self.class.name.underscore.to_sym,
                            :select => "#{external_nodes_table}.id, #{external_nodes_table}.sequence_number",
                            :conditions => {:fond_id => active_tree_ids},
                            :order => "#{table_name}.sequence_number, #{external_nodes_table}.sequence_number"
                          ).
                          map{|node| node.id}
      end

      protected

      def new_index_in_sequence
        @new_index_in_sequence ||=
          other_ordered_active_node_ids.index(preceding_active.id).to_i + 1
      end

      def new_position_in_sequence
        new_index_in_sequence + 1
      end

      def ordered_active_subtree_ids
        if @ordered_active_subtree_ids
          @ordered_active_subtree_ids
        else
          nodes = subtree.active.find(:all, :select => "id, sequence_number", :order => "sequence_number")

          @ordered_active_subtree_ids = if nodes.all?{|node| node.sequence_number.present?}
                                          nodes.map{|node| node.id}
                                        else
                                          flat_ordered_subtree(:ids_only => true, :active_only => true)
                                        end
        end
      end

      def other_ordered_active_node_ids
        @other_ordered_active_node_ids ||=
          root.subtree.active.
          find(
            :all, :select => 'id',
            :conditions => ["id NOT IN (?)", ordered_active_subtree_ids],
            :order => "sequence_number"
          ).
          map{|node| node.id}
      end

      def preceding_active
        if position > 1 && preceding_active_sibling
          preceding_active_sibling.subtree.active.
          find(:last, :select => "id, ancestry, sequence_number", :order => "sequence_number")
        else
          parent
        end
      end

      def preceding_active_sibling
        @preceding_active_sibling ||=
          siblings.active.
          find(:first, :select => "id, ancestry, sequence_number", :conditions => {:position => (position-1)})
      end

      def active_tree_ids
        @active_tree_ids ||=
          root.subtree.active.find(:all, :select => "id").map{|node| node.id}
      end

      def active_subtree_ids
        @active_subtree_ids ||=
          subtree.active.find(:all, :select => "id").map{|node| node.id}
      end

      def ordered_active_tree_ids
        root.subtree.active.find(:all, :select => 'id', :order => "sequence_number").map{|node| node.id}
      end

      def all_external_node_ids
        external_nodes_class.
          find(:all, :select => "id", :conditions => {:fond_id => root.subtree_ids}).
          map{|i|i.id}
      end

      def has_external_nodes?
        external_nodes_class.exists?(:fond_id => subtree_ids)
      end

    end
  end
end

