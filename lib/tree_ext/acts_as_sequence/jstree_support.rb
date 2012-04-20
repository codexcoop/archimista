module TreeExt
  module ActsAsSequence
    module JstreeSupport

      # When parent changes, jsTree always starts counting from zero.
      # When only position changes, the result from jsTree is different when
      # position decreases (starts counting from zero) and when position grows
      # (starts counting from one)
      def normalize_jstree_position
        self.new_position += 1 if moving_to_new_parent? || moving_up_inside_siblings?
      end

      def to_jstree_hash
        {
          :data => name,
          :attr => {
                     :id => "node-#{id}",
                     :'data-is-root' => is_root?,
                     :'data-units' => "#{units_count}" # Serve nei dialogs di units
                   }
        }
      end

      def subtree_to_jstree_hash(preset_family = self.subtree.select_for_tree.order_for_tree)
        node_hash = {}
        memoized_children = memoize_children(preset_family)

        node_hash.update( self.to_jstree_hash )
        if memoized_children.any?
          node_hash[:children] = memoized_children.collect do |child|
            child.send(__method__, preset_family) # recursion
          end
        end
        node_hash
      end

      def prepared_jstree_hash
        {:id => id}.update(to_jstree_hash)
      end

      def fast_subtree_to_jstree_hash(prepared_subtree=nil)
        prepared_subtree ||= subtree.prepare_ordered_subtree

        groups = break_groups_by_key(prepared_subtree,
                                    :key => 'ancestor_ids',
                                    :attr => 'prepared_jstree_hash',
                                    :seed => true)

        list = [groups.first.second]

        groups[1..-1].each do |ancestor_ids, *hashes|
          target_element = find_in_nested_list(list, ancestor_ids[depth..-1])
          target_element[:children] = hashes if target_element
        end

        list
      end

      def active_subtree_to_jstree_hash
        subtree_to_jstree_hash(self.subtree.select_for_tree.order_for_tree.active)
      end

      def trashed_subtree_to_jstree_hash
        subtree_to_jstree_hash(self.subtree.select_for_tree.order_for_tree.trashed)
      end

      def fast_active_subtree_to_jstree_hash
        fast_subtree_to_jstree_hash(subtree.prepare_ordered_subtree.active)
      end

      def fast_trashed_subtree_to_jstree_hash
        fast_subtree_to_jstree_hash(subtree.prepare_ordered_subtree.trashed)
      end

      def memoize_children(preset_family)
        preset_family.select{|node| node.parent_id == self.id}
      end

    end
  end
end

