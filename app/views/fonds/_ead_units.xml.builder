unless units.empty?
  units.each do |unit|
    level = "c#{start_from.succ.to_s.rjust(2,'0')}"
    otherlevel = unit.unit_type.present? ? unit.unit_type.split(' ').first : 'sconosciuto'
    xml.tag!(level, {:otherlevel => "#{otherlevel}", :level => "otherlevel", :id => "ARCH#{unit.id}"}) do
      xml.did do
        unit.unit_identifiers.each do |identifier|
          xml.unitid identifier.identifier, { :encodinganalog => "1.1", :countrycode => "it", :repositorycode => "#{identifier.identifier_source}" }
        end
        xml.unittitle unit.title, {:encodinganalog => "1.2"}

        xml.unitdate  unit.preferred_event.try(:full_display_date),
          {:normal => normalize_date_for_ead(unit.preferred_event)} if unit.preferred_event.present? && unit.preferred_event.valid?
      end
      xml << render(:partial => "ead_units.xml", :locals => { :start_from => start_from, :units => unit.descendants.all(:conditions => "id != #{unit.id}", :order => :sequence_number) })
    end
  end
end