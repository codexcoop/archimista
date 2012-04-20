module Archidate

  module Callbacks

    private

    def set_start_date
      set_start_date_format
      set_start_date_spec
      set_start_date_valid
      set_start_date_from
      set_start_date_to
    end

    def set_end_date
      if different_bounds?
        set_end_date_format
        set_end_date_from
        set_end_date_to
        set_end_date_spec
        set_end_date_valid
      end
    end

    def set_equal_bounds
      if equal_bounds?
        set_start_date
        self.end_date_place   = start_date_place
        self.end_date_from    = start_date_from
        self.end_date_to      = start_date_to
        self.end_date_spec    = start_date_spec
        self.end_date_format  = start_date_format
        self.end_date_valid   = start_date_valid
        self.end_date_display = start_date_display
      end
    end

    # Start date
    def set_start_date_format
      if start_date_format == 'Y'
        self.start_date_format =  case normalized_start_params.size
                                  when 3 then 'YMD'
                                  when 2 then 'YM'
                                  else        'Y'
                                  end
      end
    end

    def set_end_date_format
      if end_date_format == 'Y'
        self.end_date_format =  case normalized_end_params.size
                                when 3 then 'YMD'
                                when 2 then 'YM'
                                else        'Y'
                                end
      end
    end

    def set_start_date_spec
      self.start_date_spec = 'idem' if start_date_format == 'C'
    end

    def set_end_date_spec
      self.end_date_spec = 'idem' if end_date_spec.blank? || end_date_format.is_in?('C','U','O')
    end

    def set_start_date_from
      if start_date_top_level_format.is_in?('Y','C')
        self.start_date_from =  case start_date_top_level_format
                                when 'Y'
                                  if must_shift?(:start)
                                    case start_date_format
                                      when 'YMD'  then tmp_start_date_from
                                      when 'YM'   then tmp_start_date_from.try(:end_of_month)
                                      when 'Y'    then tmp_start_date_from.try(:end_of_year)
                                    end
                                  else
                                    tmp_start_date_from
                                  end
                                when'C'
                                  century_date_from(start_century, start_century_interval)
                                end
      end
    end

    def set_end_date_from
      if end_date_top_level_format.is_in?('Y','C','O','U')
        self.end_date_from =  case end_date_format
                              when 'Y','YM','YMD' then tmp_end_date_from
                              when 'C' then century_date_from(end_century, end_century_interval)
                              when 'O' then Date.new(9999,12,31)
                              when 'U' then nil
                              end
      end
    end

    def set_start_date_to
      if start_date_top_level_format.is_in?('Y','C')
        self.start_date_to =  if must_shift?(:start)
                                start_date_from
                              else
                                case start_date_format
                                when 'YMD' then start_date_from
                                when 'YM'  then start_date_from.try(:end_of_month)
                                when 'Y'   then start_date_from.try(:end_of_year)
                                when 'C'   then century_date_to(start_century, start_century_interval)
                                end
                              end
      end
    end

    def set_end_date_to
      if end_date_top_level_format.is_in?('Y','C','O','U')
        self.end_date_to =  if end_date_spec == 'ante'
                              end_date_from
                            else
                              case end_date_format
                              when 'YMD' then end_date_from
                              when 'YM'  then end_date_from.try(:end_of_month)
                              when 'Y'   then end_date_from.try(:end_of_year)
                              when 'C'   then century_date_to(end_century, end_century_interval)
                              when 'O'   then Date.new(9999,12,31)
                              when 'U'   then nil
                              end
                            end
      end
    end

    def set_start_date_valid
      self.start_date_valid ||= 'C'
    end

    def set_end_date_valid
      self.end_date_valid ||= if end_date_format == 'U'
                                'U'
                              elsif end_date_valid.blank?
                                'C'
                              end
      #self.end_date_valid = case end_date_format
      #                        when 'U' then 'U'
      #                        when 'O' then 'C'
      #                      end
    end

    def set_order_date
      self.order_date = in_memory_order_date
    end

    def set_end_date_place
      self.end_date_place = nil if end_date_top_level_format.not_in?(['Y','C'])
    end

    # => must run after_validation, so that the necessary parameters are already set
    def set_start_date_display
      self.start_date_display = in_memory_display_for(:start, :it)
    end

    # => must run after_validation, so that the necessary parameters are already set
    def set_end_date_display
      self.end_date_display   = in_memory_display_for(:end, :it)
    end

  end
end

