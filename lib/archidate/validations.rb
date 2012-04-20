module Archidate
  module Validations

    private

    def add_invalid_start_date_error
      if [start_date_from_year, start_date_from_month, start_date_from_day].any?(&:present?) && invalid_start_date?
        errors.add :start_date_from, :invalid_date
      end
    end

    def add_invalid_end_date_error
      if [end_date_from_year, end_date_from_month, end_date_from_day].any?(&:present?) && invalid_end_date?
        errors.add :end_date_from, :invalid_date
      end
    end

    # this should occur only if the method set_start_date_to is not working as expected
    def start_date_range
      if start_date_from && start_date_to && start_date_from > start_date_to
        errors.add :start_date_from, :invalid_date_range
      end
    end

    # this should occur only if the method set_end_date_to is not working as expected
    def end_date_range
      if end_date_from && end_date_to && end_date_from > end_date_to
        errors.add :end_date_from, :invalid_date_range
      end
    end

    def acceptable_start_date_specs
      if equal_bounds?
        self.class.start_date_spec_values - ['post']
      else
        self.class.start_date_spec_values
      end
    end

    def start_date_spec_against_date
      errors.add :start_date_from, :invalid_specification if start_date_spec.not_in?(acceptable_start_date_specs)
    end

    def acceptable_end_date_specs
      if equal_bounds?
        self.class.end_date_spec_values - ['ante']
      else
        self.class.end_date_spec_values
      end
    end

    def end_date_spec_against_date
      errors.add :end_date_from, :invalid_specification if end_date_spec.not_in?(acceptable_end_date_specs)
    end

    def no_future_start_date
      errors.add :start_date_from, :future_date if future_start_date?
    end

    def no_future_end_date
      errors.add :end_date_from, :future_date if future_end_date?
    end

    def no_intersection
      errors.add :start_date_from, :intersection if different_bounds? && has_intersection?
    end

    def no_inversion
      errors.add :start_date_from, :inversion if has_inversion?
    end

    def numericality_of_start_date_from_year
      if start_date_top_level_format == 'Y' && !start_date_from_year_natural?
        errors.add :start_date_from, :not_a_natural_number
      end
    end

    def numericality_of_end_date_from_year
      if end_date_top_level_format == 'Y' && !end_date_from_year_natural?
        errors.add :end_date_from, :not_a_natural_number
      end
    end

    def numericality_of_start_century
      if start_date_top_level_format == 'C' && !start_century_natural?
        errors.add :start_date_from, :not_a_natural_number
      end
    end

    def numericality_of_end_century
      if end_date_top_level_format == 'C' && !end_century_natural?
        errors.add :end_date_from, :not_a_natural_number
      end
    end

  end
end

