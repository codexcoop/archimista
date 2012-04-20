module TreeExt
  module ActsAsSequence
    module Trash

      def trash_subtree
        transaction do
          update_attributes(trash_self_statement)
          self.class.update_all(trash_descendants_statement, trash_descendants_conditions)
        end
      end

      def trash_subtree?
        trash_subtree.present?
      end

      def trash_external_nodes
        transaction do
          external_nodes_class.update_all(trash_external_nodes_statement, trash_external_nodes_conditions)
        end
      end

      def restore_external_nodes
        transaction do
          external_nodes_class.update_all(restore_external_nodes_statement, restore_external_nodes_conditions)
        end
      end

      def restore_subtree
        transaction do
          self.class.update_all(restore_subtree_statement, restore_subtree_conditions)
        end
      end

      def restore_subtree?
        restore_subtree.present?
      end

      # Returns nil unless the record is root.
      def trashed_subtrees
        return unless is_root?
        descendants.trashed_roots
      end

      private

      def trash_descendants_statement
        case self.class.connection.adapter_name.downcase
        when 'postgresql', 'mysql'
          ["#{self.class.quoted_table_name}.trashed = ?, #{self.class.quoted_table_name}.trashed_ancestor_id = ?", true, id]
        when 'sqlite'
          ["trashed = ?, trashed_ancestor_id = ?", true, id]
        end
      end

      def trash_self_statement
        {:trashed => true, :trashed_ancestor_id => nil}
      end

      def trash_descendants_conditions
        {:id => descendant_ids}
      end

      def trash_external_nodes_statement
        case external_nodes_class.adapter_name.downcase
        when 'postgresql', 'mysql'
          ["#{external_nodes_class.quoted_table_name}.trashed = ?", true]
        when 'sqlite'
          ["trashed = ?", true]
        end
      end

      def trash_external_nodes_conditions
        {:fond_id => subtree_ids}
      end

      def restore_subtree_statement
        case self.class.connection.adapter_name.downcase
        when 'postgresql', 'mysql'
          ["#{self.class.quoted_table_name}.trashed = ?, #{self.class.quoted_table_name}.trashed_ancestor_id = ?", false, nil]
        when 'sqlite'
          ["trashed = ?, trashed_ancestor_id = ?", false, nil]
        end
      end

      def restore_subtree_conditions
        {:id => subtree_ids}
      end

      def restore_external_nodes_statement
        case external_nodes_class.adapter_name.downcase
        when 'postgresql', 'mysql'
          ["#{external_nodes_class.quoted_table_name}.trashed = ?", false]
        when 'sqlite'
          ["trashed = ?", false]
        end
      end

      def restore_external_nodes_conditions
        trash_external_nodes_conditions
      end

    end
  end
end

