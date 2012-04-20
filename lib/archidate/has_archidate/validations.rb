module HasArchidate
  module Validations

    def at_most_one_preferred_event
      if self.class.cardinality == 'n' && events.select{|event| event.preferred}.size > 1
        errors.add_to_base :more_than_one_preferred_event
      end
    end

    def presence_of_preferred_event_if_events_present
      if self.class.cardinality == 'n' && events.present? && events.none?(&:preferred?)
        errors.add_to_base :no_preferred_event_if_events_present
      end
    end

  end
end

