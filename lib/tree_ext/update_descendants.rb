module TreeExt
  module UpdateDescendants

    attr_accessor :attrs_changed_before_save

    # OPTIMIZE: una sola query per aggiornare tutti gli attributi ereditati, invece di una query per attributo

    # The declared attributes will be copied from the current instance to its
    # descendants, whenever the instance is created or updated, and those attributes
    # have changed.
    # Usage:
    #
    #   class MyModel < ActiveRecord::Base
    #     extend TreeExt::UpdateDescendants
    #     update_in_descendants :other_model_id, :other_attribute
    #   end
    def update_in_descendants(*attrs)
      @attrs_changed_before_save = []
      attrs.each do |attribute|
        instance_methods = Module.new do
          attr_accessor "#{attribute}_changed_before_save".to_sym
          alias :"#{attribute}_changed_before_save?" :"#{attribute}_changed_before_save"
        end
        include instance_methods
        self.attrs_changed_before_save << attribute.to_sym

        define_tracker_for(attribute)
        define_propagator_for(attribute)

        before_save "mark_#{attribute}_changed_before_save".to_sym
        after_save "propagate_#{attribute}_in_descendants".to_sym
      end
    end

    private

    # The attribute has to be tracked with a new attr_accessor, because the record
    # is no more dirty after saved.
    def define_tracker_for(attribute)
      define_method "mark_#{attribute}_changed_before_save".to_sym do
        self.send("#{attribute}_changed_before_save=".to_sym, true) if send("#{attribute}_changed?".to_sym)
      end
    end

    # Defines the callback that update a specific attribute in descendants.
    def define_propagator_for(attribute)
      define_method "propagate_#{attribute}_in_descendants".to_sym do
        if send("#{attribute}_changed_before_save?".to_sym)
          self.class.transaction do
            self.class.update_all(["#{attribute} = ?", send(attribute)], {:id => descendant_ids})
          end
        end
      end
    end

  end
end

