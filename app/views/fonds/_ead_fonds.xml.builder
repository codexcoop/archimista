unless fonds.empty?
  fonds.each do |fond|
    level = "c#{fond.ancestry_depth.to_s.rjust(2,'0')}"
    xml.tag!(level, {:otherlevel => "#{fond.fond_type}", :level => "otherlevel", :id => "ARCH#{fond.id}"}) do
      xml.did do
        fond.fond_identifiers.each do |identifier|
          xml.unitid identifier.identifier, { :encodinganalog => "1.1", :countrycode => "it", :repositorycode => "#{identifier.identifier_source}" }
        end
        xml.unittitle fond.name, {:encodinganalog => "1.2"}

        xml.unitdate  fond.preferred_event.try(:full_display_date),
          {:normal => normalize_date_for_ead(fond.preferred_event)} if fond.preferred_event.present? && fond.preferred_event.valid?

        xml.physdesc do
          xml.extent fond.extent, {:label => "consistenza"} unless fond.extent.blank?
          xml.extent fond.length, {:label => "metri lineari"} unless fond.length.blank?
        end
      end
      xml << render(:partial => "ead_units.xml", :locals => { :start_from => fond.ancestry_depth, :units => fond.units.all(:order => :sequence_number) })
      xml << render(:partial => "ead_fonds.xml", :locals => { :fonds => fond.children.all(:conditions => "id != #{fond.id}", :order => :sequence_number) })
    end
  end
end