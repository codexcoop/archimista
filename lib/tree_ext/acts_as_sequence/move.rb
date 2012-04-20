module TreeExt
  module ActsAsSequence
    module Move

      # Virtual attributes added to the model.
      attr_accessor :new_parent_id, :new_position

      # Options:
      # :new_parent_id is required
      # :new_position is optional, if missing, the bottom is assumed
      # :jstree => true if the params come from the jstree v1.rc2, and need to be normalized
      def move(opts={})
        opts.assert_valid_keys :new_parent_id, :new_position, :jstree

        # setting virtual attributes
        self.new_parent_id  = opts[:new_parent_id]
        self.new_position   = opts[:new_position].to_i if opts[:new_position].present?

        normalize_jstree_position if opts[:jstree]

        if moving_to_new_parent?
          move_to_new_parent
        elsif moving_inside_siblings?
          move_inside_siblings
        end
      end

      private

      def move_inside_siblings
        transaction do
          insert_at(new_position)
        end
      end

      def move_to_new_parent
        transaction do
          remove_from_list
          update_attributes(:parent_id => new_parent_id)
          insert_at(new_position) if new_position.present?
        end
      end

      def moving_to_new_parent?
        parent_id.to_s != new_parent_id.to_s
      end

      def moving_up_inside_siblings?
        parent_id.to_s == new_parent_id.to_s &&
        new_position.to_i < position_was.to_i
      end

      def moving_inside_siblings?
        parent_id.to_s == new_parent_id.to_s &&
        new_position.to_i != position_was.to_i
      end

    end
  end
end

