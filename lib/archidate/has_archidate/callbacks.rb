module HasArchidate
  module Callbacks

    def nullify_events_places
      return if self.class.events_can_have_places? && self.events_have_places?
      self.events.each do |event|
        event.start_date_place = nil
        event.end_date_place   = nil
      end
    end

    def set_proper_preferred_event
      return unless events.first
      if self.class.cardinality == '1' || (self.class.cardinality == 'n' && events.size == 1)
        events.first.preferred = true
      end
    end

  end
end

