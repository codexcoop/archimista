module TreeExt
  module ActsAsExternalSequence
    module VirtualAttributes

      attr_accessor :memoized_global_position

      # The direct parent_id of the object (when the parent is of the same class),
      # or a marked id of the object of the association given as external_parent.
      # Example: if Unit is a continuation of the Fond tree (external parent is a Fond):
      # - Unit#10223 has ancestry "10222" and fond_id 2263 => its parent is the Unit#10222 => structural_parent_id 10222
      # - Unit#10222 has ancestry blank and fond_id 2263 => its parent is the Fond#2263 => structural_parent_id "F2263"
      # "F" as in "foreign"
      def structural_parent_id
        parent_id || "F#{send(self.class.external_parent_foreign_key)}"
      end

      # A symbol of the attribute which identifies the external root.
      # Example: if Unit is a continuation of the Fond tree (external parent is a Fond):
      # the external_root_id is :root_fond_id
      def external_root_id
        "root_#{self.class.external_parent_association_name}_id".to_sym
      end

      # The direct parent of the object (when the parent is of the same class),
      # or the object of the association given as external_parent.
      # Example: if Unit is a continuation of the Fond tree (external parent is a Fond):
      # - Unit#10223 has ancestry "10222" and fond_id 2263 => its parent is the Unit#10222
      # - Unit#10222 has ancestry blank and fond_id 2263 => its parent is the Fond#2263
      def structural_parent
        parent || send(self.class.external_parent_association_name)
      end

      # The root of the structural parent.
      # Example: if Unit is a continuation of the Fond tree (external parent is a Fond):
      # - current Unit parent_id is 10222 and fond_id 2263
      # - Fond#2263 has root_id 380
      # - then the structural root is Fond#380
      def structural_root
        if respond_to?(external_root_id) && send(external_root_id).present?
          self.class.external_parent_class.find(send(external_root_id))
        else
          send(self.class.external_parent_association_name).root
        end
      end

      # Example: structural ancestors be fonds, and this node be a unit.
      # If is root and has position == 1, its parent is a fond, and the preceding unit
      # is the last unit or subunit descending from the preceding fonds.
      def preceding_of_a_root_in_first_position
        return unless is_root? && position == 1
        self.class.
          find(
            :last,
            :select => "units.id, units.ancestry, units.sequence_number",
            :joins => [:fond],
            :order => "fonds.sequence_number, units.sequence_number",
            :conditions => "units.fond_id IN (#{structural_root.subtree_ids.join(', ')})
                            AND fonds.sequence_number < #{structural_parent.sequence_number}")
      end

      # Example: structural ancestors be fonds, and this node be a unit.
      # If is root and has position > 1, its parent is a fond, and the preceding unit
      # is the preceding unit belonging to the same fond, or its last subunit.
      def preceding_of_a_root_in_non_first_position
        return unless is_root? && position > 1
        self.class.
          find(:last,
            :select => "id, ancestry, sequence_number",
            :conditions => "fond_id = #{fond_id} AND ancestry_depth = #{ancestry_depth} AND position < #{position}",
            :order => "position").
          subtree.
          find(:last, :select => "id, ancestry, sequence_number", :order => "sequence_number")
      end

      # Example: structural ancestors be fonds, and this node be a unit.
      # If is not a root and has position == 1, its parent is another unit,
      # it is the first child, so its direct preceding unit must be its parent.
      def preceding_of_a_node_in_first_position
        return unless !is_root? && position == 1
        parent
      end

      # Example: structural ancestors be fonds, and this node be a unit.
      # If is not a root and has position > 1, its parent is another unit,
      # and its preceding is the preceding subunit.
      def preceding_of_a_node_in_non_first_position
        return unless !is_root? && position > 1
        siblings.
          find(:first,
            :select => "id, ancestry, sequence_number",
            :conditions => {:position => (position-1)}).
          subtree.
          find(:last, :select => "id, ancestry, sequence_number", :order => "sequence_number")
      end

      # See single methods.
      # Using elsif because the options in case are always all executed,
      # even if a prior condition is met.
      def structural_preceding_active
        preceding_of_a_root_in_first_position     ||
        preceding_of_a_root_in_non_first_position ||
        preceding_of_a_node_in_first_position     ||
        preceding_of_a_node_in_non_first_position
      end

      def last_sequence_number
        @last_sequence_number ||= structural_preceding_active.try(:sequence_number).to_i
      end

    end
  end
end

