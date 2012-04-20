module TreeExt
  module ActsAsSequence
    module TrashWithSequence

      def trash_subtree_with_external_sequence
        transaction do
          trash_subtree
          update_active_sequence
          update_full_external_sequence
        end
      end

      def restore_subtree_with_external_sequence
        transaction do
          restore_subtree
          update_full_sequence_for_moved_node
          restore_full_external_sequence
        end
      end

    end
  end
end

