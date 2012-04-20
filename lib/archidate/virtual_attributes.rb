module Archidate
  module VirtualAttributes

    attr_writer   :start_date_from_year,    :end_date_from_year,
                  :start_date_from_month,   :end_date_from_month,
                  :start_date_from_day,     :end_date_from_day,
                  :start_century,           :end_century,
                  :start_century_interval,  :end_century_interval,
                  :equal_bounds

    attr_accessor :invalid_start_date,      :invalid_end_date

    alias :invalid_start_date? :invalid_start_date

    alias :invalid_end_date? :invalid_end_date

    def start_date_from_year
      @start_date_from_year ||= from_year_for_bound(:start)
    end

    def end_date_from_year
      @end_date_from_year ||= from_year_for_bound(:end)
    end

    def start_date_from_month
      @start_date_from_month ||= from_month_for_bound(:start)
    end

    def end_date_from_month
      @end_date_from_month ||= from_month_for_bound(:end)
    end

    def start_date_from_day
      @start_date_from_day ||= from_day_for_bound(:start)
    end

    def end_date_from_day
      @end_date_from_day ||= from_day_for_bound(:end)
    end

    def start_century_interval
      @start_century_interval ||= century_interval_description(:start).try(:"[]", 0)
    end

    def end_century_interval
      @end_century_interval ||= century_interval_description(:end).try(:"[]", 0)
    end

    def start_century
      @start_century ||= century_for_bound(:start)
    end

    def end_century
      @end_century ||= century_for_bound(:end)
    end

    def full_display_date
      if equal_bound_fields?
        start_date_display.no_leading_zeros
      else
        "#{start_date_display} - #{end_date_display}".squish.no_leading_zeros
      end
    end

    def full_display_date_with_place
      a = Array.new
      b = Array.new

      a.push(start_date_place) unless start_date_place.blank?
      a.push(start_date_display)

      if equal_bound_fields?
        a.join(", ").squish.no_leading_zeros
      else
        b.push(end_date_place) unless end_date_place.blank?
        b.push(end_date_display)
        "#{a.join(", ")} - #{b.join(", ")}".squish.no_leading_zeros
      end
    end

    def equal_bounds
      if @equal_bounds.nil?
        @equal_bounds = ( equal_bounds_conditions_for_existing_record? ||
                          equal_bounds_conditions_for_new_record? )
      else
        @equal_bounds
      end
    end

    def equal_bounds?
      equal_bounds.is_in?(1,'1','true',true)
    end

    def different_bounds?
      !equal_bounds?
    end

    def start_date_from_year_natural?
      natural?(__method__)
    end

    def end_date_from_year_natural?
      natural?(__method__)
    end

    def start_century_natural?
      natural?(__method__)
    end

    def end_century_natural?
      natural?(__method__)
    end

    def future_start_date?
      start_date_from && start_date_from > Date.today
    end

    def not_future_start_date?
      !future_start_date?
    end

    def future_end_date?
      end_date_from && end_date_format.is_in?('YMD','YM','Y','C') && end_date_from > Date.today
    end

    def not_future_end_date?
      !future_end_date?
    end

    def has_intersection?
      intersection_min && intersection_max && intersection_min <= intersection_max
    end

    def has_not_intersection?
      !has_intersection?
    end

    def has_inversion?
      start_date_from       &&
      shifted_end_date_from &&
      shifted_start_date_from > shifted_end_date_from #||
      #(start_date_to && end_date_to && start_date_to > end_date_to)
    end

    def has_not_inversion?
      !has_inversion?
    end

    def start_date_top_level_format
      start_date_format.is_in?('YMD','YM','Y') ? 'Y' : start_date_format
    end

    def end_date_top_level_format
      end_date_format.is_in?('YMD','YM','Y') ? 'Y' : end_date_format
    end

    private

    def century_interval_range_for(bound)
      if send("#{bound}_date_from") && send("#{bound}_date_to") && send("#{bound}_date_format") == 'C'
        begins_with = send("#{bound}_date_from").year % 100
        to_year_remainder = send("#{bound}_date_to").year % 100
        ends_with   = to_year_remainder == 0 ? 100 : to_year_remainder

        begins_with..ends_with
      end
    end

    # Requires that start_date_from_year is already set, and that start_date_format is set to 'C'
    # Returns a range of integers, that can assume values between 1 and 100.
    # For example:  first quarter => 1..24
    #               middle => 45..54
    # Delegates to century_interval_range_for(bound)
    def start_century_interval_range
      century_interval_range_for(:start)
    end

    # Same as start_century_interval_range, but for end_date
    def end_century_interval_range
      century_interval_range_for(:end)
    end

    def century_interval_description(bound)
      if send("#{bound}_date_format") == 'C'
        self.class.century_intervals.find{|code, description|
          description[:range] == send("#{bound}_century_interval_range")
        }
      end
    end

    def display_date(bound, locale)
      if self.class.specifications.has_key?(send("#{bound}_date_spec"))
        "".tap do |display|
          display << self.class.specifications[send("#{bound}_date_spec")][:display][locale.to_sym] + " "
          display << I18n.localize(
                            send("#{bound}_date_from"),
                            :format => send("#{bound}_date_format").downcase.to_sym,
                            :locale => locale.to_sym
                          )
        end.squish
      end
    end

    def display_century(bound, locale)
      if self.class.centuries.has_key?(send("#{bound}_century").to_i)
        "".tap do |display|
          if century_interval_description(bound) && century_interval_description(bound)[1]
            display << century_interval_description(bound)[1][:human][locale.to_sym] + " "
          end
          display << self.class.display_fragments[:century][:abbr][locale.to_sym] + " "
          display << self.class.centuries[send("#{bound}_century").to_i][:roman]
        end.squish
      end
    end

    def display_with_valid(bound, display_text)
      if display_text
        if send("#{bound}_date_format").not_in?(['O','U'])
          case send("#{bound}_date_valid")
          when 'C'  then display_text
          when 'U'  then "#{display_text} ?"
          when 'Q'  then "[#{display_text}]"
          when 'UQ' then "[#{display_text} ?]"
          end
        else
          display_text
        end
      end
    end

    # post 2000 - ante 2004 # => 2000-12-31,3,2000-12-31,0,2004-01-01,0,0
    def in_memory_order_date
      [
        start_date_from.try(:strftime, "%Y-%m-%d"),
        self.class.specifications[start_date_spec].try(:"[]", :priority),
        start_date_to.try(:strftime, "%Y-%m-%d"),
        self.class.validities[start_date_valid].try(:"[]", :priority),
        end_date_to.try(:strftime, "%Y-%m-%d"),
        self.class.specifications[end_date_spec].try(:"[]", :priority),
        self.class.validities[end_date_valid].try(:"[]", :priority)
      ].
      compact.
      join('|')
    end

    def in_memory_display_for(bound, locale)
      text =  if (send("#{bound}_date_from?") || send("#{bound}_date_format") == 'U') &&
                  send("#{bound}_date_format?") &&
                  send("#{bound}_date_spec?")   &&
                  send("#{bound}_date_valid?")
              then
                case send("#{bound}_date_top_level_format")
                  when 'Y' then display_date(bound, locale)
                  when 'C' then display_century(bound, locale)
                  when 'O' then (""  if bound.to_sym == :end)
                  when 'U' then ("?" if bound.to_sym == :end)
                end
              end

      display_with_valid(bound, text).try(:squish)
    end

    def in_memory_start_date_display(locale)
      in_memory_display_for(:start, locale)
    end

    def in_memory_end_date_display(locale)
      in_memory_display_for(:end, locale)
    end

    def in_memory_display(locale)
      if equal_bound_fields?
        in_memory_start_date_display(locale)
      else
        "#{in_memory_start_date_display(locale)} - #{in_memory_end_date_display(locale)}".squish
      end
    end

    def equal_bounds_conditions_for_new_record?
      new_record?                       &&
      self.class.equal_bounds_allowed?  &&
      self.class.default_equal_bounds?
    end

    def equal_bounds_conditions_for_existing_record?
      id && self.class.equal_bounds_allowed? && equal_bound_fields?
    end

    def equal_bound_fields?
      start_date_from?    && end_date_from?   &&
      start_date_to?      && end_date_to?     &&
      start_date_format?  && end_date_format? &&
      start_date_spec?    && end_date_spec?   &&
      start_date_valid?   && end_date_valid?  &&
      start_date_from     == end_date_from    &&
      start_date_to       == end_date_to      &&
      start_date_format   == end_date_format  &&
      start_date_spec     == end_date_spec    &&
      start_date_valid    == end_date_valid
    end

    def natural?(method)
      attribute = method.to_s.split("_")[0..-2].join("_")
      send(attribute) && send(attribute).to_i > 0 && !send(attribute).to_s.match(/[^\d]/)
    end

    def bound_natural?(bound)
      send("#{bound}_date_from_year_natural?") || send("#{bound}_century_natural?")
    end

    def start_natural?
      bound_natural?(:start)
    end

    def end_natural?
      bound_natural?(:end)
    end

    def intersection_min
      [shifted_start_date_from, shifted_end_date_from].max if shifted_start_date_from && shifted_end_date_from
    end

    def intersection_max
      [shifted_start_date_to, shifted_end_date_to].min if shifted_start_date_to && shifted_end_date_to
    end

    # if beyond month's end, take the last valid day
    def tmp_date_from(bound)
      if send("#{bound}_date_top_level_format") == 'C' && send("#{bound}_century_to_year")
        Date.new("#{bound}_century_to_year")
      elsif send("#{bound}_date_top_level_format") == 'Y' && send("normalized_#{bound}_params").present?
        Date.new(*send("normalized_#{bound}_params"))
      end
    rescue
      if  send("#{bound}_date_from_month").to_i.is_in?((1..12).to_a) &&
          send("#{bound}_date_from_day").to_i.is_in?((29..31).to_a)
      then
        self.send("#{bound}_date_from_day=", send("#{bound}_date_from_day").to_i.pred)
        send(__method__, bound)
      else
        self.send("invalid_#{bound}_date=", true)
        nil
      end
    end

    def tmp_start_date_from
      tmp_date_from(:start)
    end

    def tmp_end_date_from
      tmp_date_from(:end)
    end

    def century_for_bound(bound)
      send("#{bound}_date_from").try(:year).to_i / 100 + 1 if send("#{bound}_date_from") && send("#{bound}_date_format") == 'C'
    end

    def from_year_for_bound(bound)
      send("#{bound}_date_from").try(:year) if send("#{bound}_date_format").is_in?('YMD','YM','Y','C')
    end

    def from_month_for_bound(bound)
      send("#{bound}_date_from").try(:month) if send("#{bound}_date_format").is_in?('YMD','YM')
    end

    def from_day_for_bound(bound)
      send("#{bound}_date_from").try(:day) if send("#{bound}_date_format") == 'YMD'
    end

    def must_shift?(bound)
      send("#{bound}_date_top_level_format") == 'Y' &&
      ( (bound.to_s == 'start' && start_date_spec == 'post') ||
        (bound.to_s == 'end' && end_date_spec == 'ante') )
    end

    # used in custom validations
    # example start date:
    # YMD => 2004-03-04/2004-03-04 => 2004-03-05/2004-03-05
    # YM  => 2004-03-01/2004-03-31 => 2004-04-01/2004-04-01
    # Y   => 2004-01-01/2004-12-31 => 2005-01-01/2005-01-01
    def shifted_start_date_from
      must_shift?(:start) ? start_date_from.advance(:days => 1) : start_date_from if start_date_from
    end

    # used in custom validations
    def shifted_start_date_to
      must_shift?(:start) ? shifted_start_date_from : start_date_to
    end

    # used in custom validations
    # example end date:
    # YMD => 2004-03-04/2004-03-04 => 2004-03-03/2004-03-03
    # YM  => 2004-03-01/2004-03-31 => 2004-02-29/2004-02-29
    # Y   => 2004-01-01/2004-12-31 => 2003-12-31/2003-12-31
    def shifted_end_date_from
      must_shift?(:end) ? end_date_from.advance(:days => -1) : end_date_from if end_date_from
    end

    # used in custom validations
    def shifted_end_date_to
      must_shift?(:end) ? shifted_end_date_from : end_date_to
    end

  end
end

