module TreeExt
  module ActsAsExternalSequence
    class Classify

      attr_accessor :model_class, :record_ids, :new_external_parent_id, :belongs_to, :valid

      alias_method :valid?, :valid

      def initialize(opts={})
        opts.each { |attribute, value| self.send("#{attribute}=".to_sym, value) }
        require_options([:model_class, :record_ids, :new_external_parent_id, :belongs_to], opts)
      end

      def require_options(required, given)
        unless required.to_set == given.keys.to_set && required.all?{|option| send(option).present?}
          raise ArgumentError, required.map{|o| o.inspect}.join(', ') + " options are required"
        end
      end

      def valid?
        return @valid if defined? @valid
        @valid = false
      end

      def association
        @association ||= model_class.reflect_on_association(belongs_to.to_sym)
      end

      def foreign_key
        @foreign_key ||= association.association_foreign_key.to_sym
      end

      def external_parent_class
        @external_parent_class ||= association.klass
      end

      def new_external_parent
        @new_external_parent ||= external_parent_class.find( new_external_parent_id )
      end

      def new_external_root
        @new_external_root ||= new_external_parent.root
      end

      def records
        @records ||= model_class.find :all,
                      :order => 'sequence_number',
                      :conditions => [
                        "id IN (:record_ids) AND #{model_class.connection.quote_column_name(foreign_key.to_s)} NOT IN (:new_parent_id)",
                        {
                          :record_ids => record_ids,
                          :external_foreign_key => foreign_key.to_s,
                          :new_parent_id => new_external_parent_id
                        }
                      ]
      end

      def old_external_parent_ids
        records.map{|record| record.send(foreign_key) }.uniq
      end

      def old_external_parents
        external_parent_class.find(old_external_parent_ids)
      end

      def old_external_roots
        @old_external_roots ||= external_parent_class.find(old_external_parents.map{ |rec| rec.root_id })
      end

      def starting_position
        return @starting_position if @starting_position
        previous_record     = model_class.prepare_position_by('position DESC').first(:conditions => {foreign_key => new_external_parent_id})
        @starting_position  = previous_record ? (previous_record.position.to_i + 1) : 1
      end

      def classify
        model_class.transaction do
          records.each_with_index do |record, index|
            record.send("#{foreign_key}=".to_sym, new_external_parent_id)
            record.position = starting_position + index + 1
            unless self.valid = record.save
              raise ActiveRecord::Rollback
            end
          end

          old_external_roots.each{ |root| root.rebuild_external_sequence_by('position') }
          raise ActiveRecord::Rollback unless self.valid = old_external_roots.map { |root| root.rebuild_external_sequence }.all?
          unless old_external_roots.map{|root| root.id }.include? new_external_root.id
            new_external_root.rebuild_external_sequence_by('position')
            raise ActiveRecord::Rollback unless self.valid = new_external_root.rebuild_external_sequence
          end
        end

        # Recalculate units_count of root fond and its descendants
        tree_fond_ids = new_external_root.descendant_ids << new_external_root.id
        Unit.bulk_update_fonds_units_count(tree_fond_ids)

        valid?
      end

    end
  end
end

