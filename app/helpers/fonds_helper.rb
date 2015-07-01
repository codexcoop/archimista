module FondsHelper

  # NormalizeDateForEAD
  def normalize_date_for_ead(event)
    if event.equal_bounds?
      "#{normalize_bound event.start_date_from, event.start_date_format}"
    else
      "#{normalize_bound event.start_date_from, event.start_date_format}/#{normalize_bound event.end_date_from, event.end_date_format}"
    end
  end

  def normalize_bound(date, format)
    case format
    when 'Y'
      date.year.to_s
    when 'O'
      String.new
    else
      date.to_s.underscore.camelize
    end
  end

end