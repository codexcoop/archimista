module TreeExt
  module ActsAsSequence
    module MoveWithSequence

      # Options:
      # :new_parent_id is required
      # :new_position is required
      # :jstree => true if the params come from the jstree v1.rc2, and need to be normalized
      def move_with_external_sequence(opts={})
        opts.assert_valid_keys :new_parent_id, :new_position, :jstree

        # setting virtual attributes
        self.new_parent_id  = opts[:new_parent_id]
        self.new_position   = opts[:new_position].to_i if opts[:new_position].present?

        normalize_jstree_position if opts[:jstree]

        if moving_to_new_parent?
          move_with_external_sequence_to_new_parent
        elsif moving_inside_siblings?
          move_with_external_sequence_inside_siblings
        end
      end

      private

      def move_with_external_sequence_inside_siblings
        transaction do
          move_inside_siblings
          update_full_sequence_for_moved_node
          if has_external_nodes?
            update_full_external_sequence
          else
            true
          end
        end
      end

      def move_with_external_sequence_to_new_parent
        transaction do
          move_to_new_parent
          update_full_sequence_for_moved_node
          if has_external_nodes?
            update_full_external_sequence
          else
            true
          end
        end
      end

    end
  end
end

