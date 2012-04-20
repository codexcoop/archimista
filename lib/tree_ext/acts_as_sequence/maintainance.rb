module TreeExt
  module ActsAsSequence
    module Maintainance

      def self.included(klass)
        klass.extend(ClassMethods)
      end

      def rebuild_units_positions
        return unless is_root?

        Unit.update_all(["position = ? AND root_fond_id = ?", nil, root_id], :fond_id => subtree_ids)

        flat_ordered_subtree.each do |node|
          root_unit_position = 1
          node.units.roots.find(:all, :order => 'legacy_position').each do |root_unit|
            root_unit.update_attribute(:position, root_unit_position)
            root_unit_position += 1
            subunit_position = 1
            root_unit.children.find(:all, :order => 'legacy_position').each do |subunit|
              subunit.update_attribute(:position, subunit_position)
              subunit_position  += 1
            end
          end
        end
      end

      module ClassMethods

        def rebuild_units_positions_for_all_roots
          puts "Rebuilding positions for all the units belonging to root fonds"
          Fond.roots.each do |root_fond|
            Unit.transaction do
              root_fond.rebuild_units_positions
            end
            puts "set positions for units of fond ##{root_fond.id}, #{root_fond.name}"
          end
        end

        def rebuild_units_sequence_numbers_for_all_roots
          t1 = Time.now
          puts "Rebuilding sequence numbers for all the units belonging to root fonds"
          Fond.roots.each do |root_fond|
            fonds_count = root_fond.rebuild_sequence
            units_count = root_fond.rebuild_external_sequence
            if units_count.to_i > 0 || fonds_count.to_i > 0
              puts "set sequence numbers for units of fond ##{root_fond.id}, #{fonds_count.to_i} fonds, #{units_count.to_i} units"
            else
              puts "no units for fond ##{root_fond.id}"
            end
          end
          t2 = Time.now
          puts "#{t2-t1} seconds"
        end

      end # ClassMethods

    end
  end
end

