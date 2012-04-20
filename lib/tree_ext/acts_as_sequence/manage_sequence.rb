module TreeExt
  module ActsAsSequence
    module ManageSequence

      attr_accessor :all_sequence_ids,
                    :active_sequence_ids,
                    :inactive_sequence_ids,
                    :id_positions,
                    :sql_order_for_positions,
                    :scope_options_for_positions,
                    :values_for_rearrangement,
                    :filter_ids

      # OPTIMIZE: [Luca] per tutti i metodi sulla sequence: riconsiderate le transactions sulla falsariga dei metodi sulle positions
      def rebuild_sequence
        return unless is_root?
        initialize_sequence_ids :all => subtree_ids,
                                :active => flat_ordered_subtree(:ids_only => true, :active_only => true)
        self.values_for_rearrangement = values_for_sequence
        perform_rearrangement(table_name, 'sequence_number')
        valid?
      end

      # OPTIMIZE: [Luca] vedere se possibile memorizzare una query sul subtree_ids
      def rebuild_external_sequence
        initialize_sequence_ids(
          :all => external_nodes_class.find(:all, :select => "id", :conditions => {:fond_id => subtree_ids}).map{|i|i.id},
          :active => flat_ordered_external_nodes(:active_only => true, :ids_only => true) )
        self.values_for_rearrangement = values_for_sequence
        perform_rearrangement(external_nodes_table, 'sequence_number')
        valid?
      end

      def external_nodes_groups_reordered
        external_descendant_nodes( scope_options_for_positions ).
        prepare_position_by( sql_order_for_positions ).
        group_by{|external_node|
          external_nodes_class.list_scope_fields.map{|field| external_node.send( field )}
        }
      end

      def external_nodes_repositioned
        external_nodes_groups_reordered.to_a.map do |list_scope, ordered_nodes|
          ordered_nodes.each_with_index do |node, index|
            node.position = index + 1
          end
        end.flatten(1)
      end

      # OPTIMIZE: [Luca] arguments must be sanitized
      # examples:
      # - simple: Fond.find(375).rebuild_external_sequence_by("reference_number")
      # - more options: Fond.find(375).rebuild_external_sequence_by("unit_events.order_date", {:joins => "LEFT OUTER JOIN unit_events ON units.id = unit_events.unit_id", :conditions => {:unit_events => {:preferred => true}}})
      def rebuild_external_sequence_by( sql_order_for_positions, scope_options_for_positions=nil, filter_ids=nil )
        self.sql_order_for_positions      = sql_order_for_positions
        self.scope_options_for_positions  = scope_options_for_positions
        self.filter_ids = filter_ids

        transaction do
          self.id_positions = external_nodes_repositioned.map{|node| [node.id, node.position]}
          self.values_for_rearrangement = id_positions
          perform_rearrangement(external_nodes_table, 'position')
          rebuild_external_sequence
        end
      end

      def save_new_in_sequence
        return unless new_record?
        transaction do
          save
          insert_in_sequence
        end
        valid?
      end

      def insert_in_sequence
        if is_root?
          initialize_root_sequence
        else
          update_sequence_in_new_node
        end
        valid?
      end

      def update_full_sequence_for_moved_node
        initialize_sequence_ids :all => root.subtree_ids,
                                :active => rearranged_tree_ids_for_moved_node
        self.values_for_rearrangement = values_for_sequence
        perform_rearrangement(table_name, 'sequence_number')
        valid?
      end

      def update_full_external_sequence
        initialize_sequence_ids :all => all_external_node_ids,
                                :active => rearranged_external_node_ids
        self.values_for_rearrangement = values_for_sequence
        perform_rearrangement(external_nodes_table, 'sequence_number')
        valid?
      end

      def restore_full_external_sequence
        # rebuild required for the current node, beacuse it was inactive, and its
        # external nodes had no sequence_number
        rebuild_external_sequence
        initialize_sequence_ids :all => all_external_node_ids,
                                :active => rearranged_external_node_ids
        self.values_for_rearrangement = values_for_sequence
        perform_rearrangement(external_nodes_table, 'sequence_number')
        valid?
      end

      # considers only nodes that are active and already have a sequence_number
      # so to be used for example after trashing, not after restoring
      def update_active_sequence
        initialize_sequence_ids :all => root.subtree_ids,
                                :active => ordered_active_tree_ids
        self.values_for_rearrangement = values_for_sequence
        perform_rearrangement(table_name, 'sequence_number')
        valid?
      end

      private

      def initialize_root_sequence
        self.class.update_all("sequence_number = 1", {:id => id}) if id.present? && is_root?
      end

      def update_sequence_in_new_node
        if id.present? && !is_root? && root_id.present?
          self.class.update_all(
            "sequence_number = sequence_number+1",
            "sequence_number >= #{new_position_in_sequence} AND ancestry LIKE '#{root_id}%'"
          )
          self.class.update_all("sequence_number = #{new_position_in_sequence}", {:id => id})
        end
      end

      def initialize_sequence_ids(opts={})
        self.all_sequence_ids       = opts[:all]    || []
        self.active_sequence_ids    = opts[:active] || []
        self.inactive_sequence_ids  = all_sequence_ids - active_sequence_ids
      end

      def values_for_sequence
        values_pairs = []
        active_sequence_ids.each_with_index{|id, index| values_pairs << [id, index+1]}
        values_pairs += inactive_sequence_ids.map{|id| [id, nil]}
        values_pairs
      end

      def values_sets_for_rearrangement(slice_size=10_000)
        values_for_rearrangement.each_slice(slice_size).map
      end

      def bulk_sql_values_sets
        values_sets_for_rearrangement.map do |values|
          values.map do |node_id, rank|
            "(#{node_id}, #{rank || 'NULL'})"
          end.
          join(", ")
        end
      end

      def tmp_table_bulk_inserts
        case connection.adapter_name.downcase
          when 'postgresql', 'mysql', 'mysql2'
            bulk_sql_values_sets.map do |sql_values_set|
              "INSERT INTO tmp_ordered_nodes (node_id, rank) VALUES #{sql_values_set}"
            end
          when 'sqlite'
            values_sets_for_rearrangement.map do |values|
              values.map do |node_id, rank|
                "INSERT INTO tmp_ordered_nodes (node_id, rank)
                VALUES (#{node_id}, #{rank || 'NULL'})"
              end
            end.flatten
        end
      end

      def nodes_rearrangement_sql(given_table_name, rank_column)
        filter_condition = String.new
        filter_condition = "AND #{given_table_name}.id IN (#{self.filter_ids})" unless self.filter_ids.blank?

        case connection.adapter_name.downcase
          when 'mysql', 'mysql2'
            "UPDATE #{given_table_name}, tmp_ordered_nodes
            SET #{given_table_name}.#{rank_column} = tmp_ordered_nodes.rank
            WHERE #{given_table_name}.id = tmp_ordered_nodes.node_id
            #{filter_condition}".squish
          when 'sqlite'
            "UPDATE #{given_table_name}
             SET #{rank_column} = (SELECT tmp_ordered_nodes.rank
                                  FROM tmp_ordered_nodes
                                  WHERE #{given_table_name}.id = tmp_ordered_nodes.node_id
                                  #{filter_condition})".squish
          when 'postgresql'
            "UPDATE #{given_table_name}
            SET #{rank_column} = tmp_ordered_nodes.rank
            FROM tmp_ordered_nodes
            WHERE #{given_table_name}.id = tmp_ordered_nodes.node_id
            #{filter_condition}".squish
        end
      end

      def perform_rearrangement(given_table_name, rank_column)
        TmpOrderedNode.transaction do
          TmpOrderedNode.delete_all
          tmp_table_bulk_inserts.each { |bulk_insert| connection.execute(bulk_insert) }
          transaction do
            connection.execute(nodes_rearrangement_sql(given_table_name, rank_column))
          end
        end
      end

    end
  end
end

