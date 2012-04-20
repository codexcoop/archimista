xml.instruct! :xml, :version => "1.0", :encoding => "UTF-8"
xml.declare! :DOCTYPE, :ead, :PUBLIC,
  "+//ISBN 1-931666-00-8//DTD ead.dtd (Encoded Archival Description (EAD) Version 2002)//EN",
  "ead.dtd"

xml.ead do
  xml.eadheader :countryencoding => "iso8859-1",
    :dateencoding => "iso8601",
    :langencoding => "iso639-2b",
    :relatedencoding => "ISAD(G)",
    :repositoryencoding => "iso15511",
    :scriptencoding => "iso15924" do

    xml.eadid :countrycode => "it", :encodinganalog => "identifier", :identifier => "#{@fond.name.parameterize.underscore}.xml"
    xml.filedesc do
      xml.titlestmt do
        xml.titleproper @fond.name, {:encodinganalog => "title"}
        xml.author @fond.projects.first.name, {:encodinganalog => "creator"} unless @fond.projects.blank?
      end
      xml.publicationstmt do
        xml.publisher "#{APP_NAME} #{APP_VERSION}", {:encodinganalog => "publisher"}
      end
    end
    xml.profiledesc do
      xml.creation do
        xml.text! "#{APP_CREATOR}"
        xml.date Date.today.to_s, {:normal => "#{Date.today.to_s.gsub('-','')}"}
      end
    end
  end
  xml.archdesc :audience => "external", :relatedencoding => "ISAD(G)", :type => "archimate",  :level => "otherlevel", :otherlevel => "#{@fond.fond_type}", :id => "ARCH#{@fond.id}" do
    xml.did do
      @fond.fond_identifiers.each do |identifier|
        xml.unitid identifier.identifier, { :encodinganalog => "1.1", :countrycode => "it", :repositorycode => "#{identifier.identifier_source}" }
      end
      xml.unittitle @fond.name, {:encodinganalog => "1.2"}
      xml.unitdate @fond.preferred_event.try(:full_display_date),
        {:normal => normalize_date_for_ead(@fond.preferred_event) } if @fond.preferred_event.present? && @fond.preferred_event.valid?

      xml.physdesc do
        xml.extent @fond.extent, {:label => "consistenza"} unless @fond.extent.blank?
        xml.extent @fond.length, {:label => "metri lineari"} unless @fond.length.blank?
      end
      xml.origination do
        @fond.creators.each do |creator|
          case creator.creator_type
          when 'C'
            xml.corpname creator.preferred_name.name
          when 'P'
            xml.persname creator.preferred_name.name
          when 'F'
            xml.famname creator.preferred_name.name
          end
        end
      end
      xml.repository do
        @fond.custodians.each do |custodian|
          xml.corpname custodian.preferred_name.name
        end
      end
      xml.abstract @fond.abstract
    end
    xml.dsc do
      xml << render(:partial => "ead_units.xml", :locals => { :start_from => @fond.ancestry_depth, :units => @fond.units.all(:order => :sequence_number) })
      if @fond.has_children?
        xml << render(:partial => "ead_fonds.xml", :locals => { :fonds => @fond.children.all(:conditions => "id != #{@fond.id}", :order => :sequence_number)})
      end
    end
  end
end