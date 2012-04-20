module Archidate
  module Normalizations

    private

    def normalized_date_params(bound)
      if send("#{bound}_date_format").is_in?('YMD','YM','Y','C')
        [send("#{bound}_date_from_year"), send("#{bound}_date_from_month"), send("#{bound}_date_from_day")].to_naturals
      end
    end

    def normalized_start_params
      normalized_date_params(:start)
    end

    def normalized_end_params
      normalized_date_params(:end)
    end

    def century_to_year(bound)
      (send("#{bound}_century").to_i - 1) * 100 + 1 if (send("#{bound}_century") && send("#{bound}_date_format") == 'C')
    end

    def start_century_to_year
      century_to_year(:start)
    end

    def end_century_to_year
      century_to_year(:end)
    end

    def first_year_of_century(year)
      year.to_i/100*100 + 1
    end

    def beginning_of_century(year)
      Date.new(first_year_of_century(year))
    end

    def end_of_century(year)
      (beginning_of_century(year) + 99.year).end_of_year
    end

    def beginning_of_century_interval(year, interval_name)
      if self.class.century_intervals[interval_name.to_s]
        ( beginning_of_century(year) +
          (self.class.century_intervals[interval_name.to_s][:range].first-1).year ).
        beginning_of_year
      end
    end

    def end_of_century_interval(year, interval_name)
      if self.class.century_intervals[interval_name.to_s]
        ( beginning_of_century(year) +
          (self.class.century_intervals[interval_name.to_s][:range].last-1).year ).
        end_of_year
      end
    end

    def century_date(side_of_bound, century, century_interval=nil)
      return if century.nil? || century.to_s.match(/[^\d]/)
      year = (century.to_i - 1) * 100 + 1
      if century_interval.present?
        if century_interval.is_in?(self.class.century_intervals.keys)
          case side_of_bound
            when :beginning then beginning_of_century_interval(year, century_interval)
            when :end then end_of_century_interval(year, century_interval)
          end
        else
          raise ArgumentError, "unknown century interval key"
        end
      else
        case side_of_bound
          when :beginning then beginning_of_century(year)
          when :end then end_of_century(year)
        end
      end
    end

    def century_date_from(century, century_interval=nil)
      century_date(:beginning, century, century_interval)
    end

    def century_date_to(century, century_interval=nil)
      century_date(:end, century, century_interval)
    end

  end
end

