module HasArchidate
  module VirtualAttributes

    def events_for_view
      # array#sort_by instead of scope, because the scope loose track of
      # new records (valid and invalid)
      events = self.send(self.class.events.to_sym).sort_by { |e| e.preferred ? 1 : 0 }.reverse
      events << self.events.build if events.empty?
      events.first.preferred = true if events.size == 1 && events.first.new_record?
      events
    end

    def events_have_places?
      condition = self.class.events_have_places_when
      case condition
        when Proc           then condition.call(self)
        when Symbol, String then send(condition.to_sym)
      end
    end

    def events_have_not_places?
      !events_have_places?
    end

    # must be used only in collections where the fields of the preferred event
    # have been selected in the named scope
    # OPTIMIZE: molto simile a full_display_date, valutare se è possibile unificare
    def preferred_display_date
      return unless [:start_date_display, :end_date_display].all? { |meth| respond_to? meth }
      [start_date_display, end_date_display].select(&:present?).join(" - ") if start_date_display.present?
    end

  end
end

