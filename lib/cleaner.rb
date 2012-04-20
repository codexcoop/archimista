module Cleaner

  private 
  
  def trimmed_fields(*fields)
    before_validation do |record|
      fields.each{|f| record[f] = record[f].strip.squeeze(' ') if record[f]}
    end
  end

  def squished_fields(*fields)
     before_validation do |record|
      fields.each{|f| record[f] = record[f].squish if record[f]}
    end
  end

  def clean_protocol_url(url_field, opts={})
    before_validation do |record|
      conditions = [record.send(url_field.to_sym).match(/^https{0,1}:\/\//).nil?]
      conditions << opts[:if].call(record) if opts[:if].is_a? Proc
      record.send("#{url_field}=", "http://#{record.send(url_field.to_sym)}") if conditions.all?
    end
  end

  def blank_default(*fields)
    before_validation do |record|
      fields.each do |attr_name|
        record.send("#{attr_name}=".to_sym, I18n.translate("activerecord.blank_defaults.#{name.underscore}.#{attr_name}")) if record.send(attr_name).blank?
      end
    end
  end

  def remove_blank_other_names
    before_validation do |record|
      record.other_names.each do |other_name|
        if other_name.name.blank?
          other_name.destroy
        end
      end
    end
  end

  #def remove_blank_iccd_tsk
  #  after_validation do |record|
  #    if record.iccd_description && record.iccd_description.tsk.blank?
  #      record.iccd_description.destroy
  #      record.iccd_tech_spec.destroy
  #      record.iccd_authors.each do |iccd_author|
  #       iccd_author.destroy
  #      end
  #    end
  #  end
  #end

end