# Override class DocumentStyle for our own purpose

# TODO: move this to lib, if possible

module RTF
  class DocumentStyle < Style

    # Attribute accessor.
    attr_reader :paper, :left_margin, :right_margin, :top_margin,
      :bottom_margin, :gutter, :orientation, :enable_facing_pages,
      :enable_widow_control, :enable_title_page

    # Attribute mutator.
    attr_writer :paper, :left_margin, :right_margin, :top_margin,
      :bottom_margin, :gutter, :orientation, :enable_facing_pages,
      :enable_widow_control, :enable_title_page

    # This is a constructor for the DocumentStyle class. This creates a document
    #   style with a default paper setting of A4 and portrait orientation (all
    #   other attributes are nil).
    def initialize
      @paper         = Paper::A4
      @left_margin   = DEFAULT_LEFT_MARGIN
      @right_margin  = DEFAULT_RIGHT_MARGIN
      @top_margin    = DEFAULT_TOP_MARGIN
      @bottom_margin = DEFAULT_BOTTOM_MARGIN
      @gutter        = nil
      @orientation   = PORTRAIT
      @enable_facing_pages = false
      @enable_widow_control = false
      @enable_title_page = false
    end

    # This method generates a string containing the prefix associated with a
    # style object.
    #
    # ==== Parameters
    # document::  A reference to the document using the style.
    def prefix(fonts=nil, colours=nil)
      text = StringIO.new

      if orientation == LANDSCAPE
        text << "\\paperw#{@paper.height}"    unless @paper.nil?
        text << "\\paperh#{@paper.width}"     unless @paper.nil?
      else
        text << "\\paperw#{@paper.width}"     unless @paper.nil?
        text << "\\paperh#{@paper.height}"    unless @paper.nil?
      end
      text << "\\margl#{@left_margin}"        unless @left_margin.nil?
      text << "\\margr#{@right_margin}"       unless @right_margin.nil?
      text << "\\margt#{@top_margin}"         unless @top_margin.nil?
      text << "\\margb#{@bottom_margin}"      unless @bottom_margin.nil?
      text << "\\gutter#{@gutter}"            unless @gutter.nil?
      text << "\\sectd\\lndscpsxn"            if @orientation == LANDSCAPE
      text << "\\facingp\\margmirror"         unless @enable_facing_pages == false
      text << "\\widowctrl"                   unless @enable_widow_control == false
      text << "\\titlepg"                     unless @enable_title_page == false

      text.string
    end
  end
end

class RtfBuilder < ActiveRecord::Base
  # See: http://railscasts.com/episodes/193-tableless-model See:
  # http://codetunes.com/2008/07/20/tableless-models-in-rails
  def self.columns() @columns ||= []; end

  def self.column(name, sql_type = nil, default = nil, null = true)
    columns << ActiveRecord::ConnectionAdapters::Column.new(name.to_s, default, sql_type.to_s, null)
  end

  column :dest_file, :string
  column :target_id, :integer

  def fond_printable_attributes
    [
      "preferred_event.full_display_date",
      "fond_type",
      "length",
      "extent",
      "abstract",
      "description",
      "history",
      "arrangement_note",
      "related_materials",
      "access_condition",
      "access_condition_note",
      "use_condition",
      "use_condition_note",
      "type_materials",
      "preservation",
      "preservation_note",
      "description_type",
      "note",
      "units_count"
    ]
  end

  def unit_printable_attributes
    [
      "title",
      "preferred_event.full_display_date_with_place",
      "sequence_number",
      "reference_number",
      "unit_type",
      "medium",
      "content",
      "arrangement_note",
      "related_materials",
      "physical_type",
      "physical_description",
      "physical_container_type",
      "physical_container_title",
      "physical_container_number",
      "preservation",
      "preservation_note",
      "restoration",
      "access_condition",
      "access_condition_note",
      "use_condition",
      "use_condition_note"
    ]
  end

  # unit_NON_printable_attributes: "tsk", "tmp_reference_number",
  # "tmp_reference_string", "folder_number", "file_number", "sort_letter",
  # "sort_number", "note"


  def custodian_printable_attributes
    [
      "headquarter_address",
      "custodian_type.custodian_type",
      "legal_status",
      "owner",
      "contact_person",
      "history",
      "administrative_structure",
      "collecting_policies",
      "holdings",
      "accessibility",
      "services",
      "custodian_contacts"
    ]
  end

  def creator_printable_attributes
    [
      "preferred_event.full_display_date",
      "creator_type",
      "creator_corporate_type.corporate_type",
      "residence",
      "abstract",
      "history",
      "note"
    ]
  end

  def project_printable_attributes
    [
      "name",
      "project_type",
      "display_date",
      "description"
    ]
  end

  def source_printable_attributes
    [
      "short_title",
      "formatted_source"
    ]
  end

  def custodian_printable_attributes
    [
      "headquarter_address",
      "custodian_type.custodian_type",
      "legal_status",
      "owner",
      "contact_person",
      "history",
      "administrative_structure",
      "collecting_policies",
      "holdings",
      "accessibility",
      "services"
    ]
  end

  def stylesheet_codes
    stylesheet_codes = Hash.new
    start = 19
    entities = ["fond", "unit", "custodian", "creator", "project", "source"]

    entities.each do |entity|
      self.send("#{entity}_printable_attributes").each do |attribute|
        methods = attribute.split('.')
        stylesheet_codes.store("#{entity}_#{methods[0]}", start)
        start+= 1
      end
    end

    stylesheet_codes
  end

  def stylesheet
    stylesheet = String.new
    stylesheet << "{\\s15\\widctlpar \\f0\\fs20\\lang1040 \\sbasedon0\\snext15 archimista_header;}\n"
    stylesheet << "{\\s16\\widctlpar \\f0\\fs20\\lang1040 \\sbasedon0\\snext16 archimista_section_header;}\n"
    stylesheet << "{\\s17\\widctlpar \\f0\\fs20\\lang1040 \\sbasedon0\\snext17 archimista_scons;}\n"
    stylesheet << "{\\s18\widctlpar \\f0\\fs20\\lang1040 \\sbasedon0\\snext18 archimista_sprod;}\n"

    stylesheet_codes.each do |attribute, code|
      stylesheet << "{\\s#{code}\\widctlpar \\f0\\fs20\\lang1040 \\sbasedon0\\snext#{code} #{attribute};}\n"
    end
    stylesheet
  end

  def document_styles
    styles = {}

    styles['P'] = ParagraphStyle.new
    styles['P'].justification = ParagraphStyle::FULL_JUSTIFY

    styles['TITLE'] = ParagraphStyle.new
    styles['TITLE'].justification = ParagraphStyle::CENTER_JUSTIFY

    styles['TITLE_DEFAULT'] = CharacterStyle.new
    styles['TITLE_DEFAULT'].font_size = 40

    styles['DEFAULT'] = CharacterStyle.new
    styles['DEFAULT'].font_size = 20

    styles['STRONG'] = CharacterStyle.new
    styles['STRONG'].bold      = true
    styles['STRONG'].font_size = 20

    styles['EM'] = CharacterStyle.new
    styles['EM'].italic      = true
    styles['EM'].font_size = 20

    styles['H1'] = CharacterStyle.new
    styles['H1'].bold      = true
    styles['H1'].font_size = 30

    styles['H2'] = CharacterStyle.new
    styles['H2'].font_size = 28
    styles['H2'].capitalise = true

    styles['H3'] = CharacterStyle.new
    styles['H3'].font_size = 26
    styles['H3'].bold = true

    styles['H4'] = CharacterStyle.new
    styles['H4'].bold      = true
    styles['H4'].font_size = 24

    styles
  end

  def build_fond_rtf_file
    fonds = Fond.subtree_of(self.target_id).active.all(
      :include => [
        :preferred_event, :sources,
        [:units => :preferred_event],
        [:creators => [:preferred_name, :preferred_event, :creator_legal_statuses, :sources]],
        [:custodians => [:preferred_name, :custodian_buildings, :custodian_contacts, :sources]]
      ],
      :order => "sequence_number")

    root_fond = fonds.first
    sequence_numbers = Unit.display_sequence_numbers_of(root_fond)

    tmp = "#{Rails.root}/tmp/tmp.rtf"

    styles = document_styles

    document_style = RTF::DocumentStyle.new()
    document_style.enable_facing_pages  = true
    document_style.enable_widow_control = true
    document_style.enable_title_page    = true

    document = Document.new(Font.new(Font::ROMAN, 'Times New Roman'), document_style)

    document.information.title = root_fond.name
    document.information.author = "Archimista"

    document.store(CommandNode.new(document, "\\headerr\\pard\\qr\\plain\\f0\\fs18#{document.information.title}\\par", nil, false))
    document.store(CommandNode.new(document, "\\headerl\\pard\\ql\\plain\\f0\\fs18#{document.information.title}\\par", nil, false))
    document.store(CommandNode.new(document, "\\footerr\\pard\\qr\\plain\\f0\\fs18\\chpgn\\par", nil, false))
    document.store(CommandNode.new(document, "\\footerl\\pard\\ql\\plain\\f0\\fs18\\chpgn\\par", nil, false))

    document.store(CommandNode.new(self, "\\stylesheet#{stylesheet}", nil, false))

    title = []
    title.push(root_fond.name)
    title.push(root_fond.preferred_event.full_display_date) if root_fond.preferred_event.present?

    title_page document, styles, title.join("\n")

    fonds.each do |fond|

      h1(document, styles, fond.name, "\\s#{stylesheet_codes['fond_name']}")

      if fond.custodians.present?
        h2(document, styles, Custodian.human_name)
        fond.custodians.each do |custodian|
          h3(document, styles, custodian.display_name, "\\s#{stylesheet_codes['custodian_display_name']}")
          custodian_printable_attributes.each do |attribute|
            methods = attribute.split('.')
            if custodian.send(methods[0].to_sym).present?
              strong(document, styles, Custodian.human_attribute_name(methods[0]))
              index = "custodian_#{methods[0]}"
              if attribute.include?('.')
                text = custodian.send(methods[0].to_sym).send(methods[1].to_sym).to_s
              else
                if attribute == 'legal_status'
                  text = translate_value(custodian.send(attribute.to_sym).to_s)
                else
                  text = custodian.send(attribute.to_sym).to_s
                end
              end
              p(document, styles, text, "\\s#{stylesheet_codes[index]}")
            end
          end
          if custodian.custodian_contacts.present?
            contacts = []
            strong(document, styles, Custodian.human_attribute_name("contacts"))
            custodian.custodian_contacts.each do |contact|
              contacts.push("#{Custodian.human_attribute_name(contact.contact_type)}: #{contact.contact}")
            end
            p(document, styles, contacts.join(', '), "\\s#{stylesheet_codes['custodian_custodian_contacts']}")
          end
          if custodian.sources.present?
            strong(document, styles, Source.human_name({:count => custodian.sources.size}))
            custodian.sources.each do |source|
              em(document, styles, source.short_title, "\\s#{stylesheet_codes['source_short_title']}")
              p(document, styles, formatted_source(source), "\\s#{stylesheet_codes['source_formatted_source']}")
            end
          end
        end
      end

      if fond.creators.present?
        h2(document, styles, Creator.human_name({:count => fond.creators.size}))
        fond.creators.each do |creator|
          h3(document, styles, creator.display_name, "\\s#{stylesheet_codes['creator_display_name']}")
          creator_printable_attributes.each do |attribute|
            methods = attribute.split('.')
            if creator.send(methods[0].to_sym).present?
              strong(document, styles, Creator.human_attribute_name(methods[0]))
              index = "creator_#{methods[0]}"
              if attribute.include?('.')
                text = creator.send(methods[0].to_sym).send(methods[1].to_sym).to_s
              else
                if attribute == 'creator_type'
                  text = Creator.human_attribute_name(creator.send(attribute.to_sym).to_s)
                else
                  text = creator.send(attribute.to_sym).to_s
                end
              end
              p(document, styles, text, "\\s#{stylesheet_codes[index]}")
            end
          end
          if creator.creator_legal_statuses.present?
            statuses = []
            strong(document, styles, Creator.human_attribute_name('legal_status'))
            creator.creator_legal_statuses.each do |cls|
              text = translate_value(cls.legal_status)
              text.concat( "[#{cls.note}]") if cls.note
              statuses.push(text)
            end
            list document, statuses, styles
          end
          if creator.sources.present?
            strong(document, styles, Source.human_name({:count => creator.sources.size}))
            creator.sources.each do |source|
              em(document, styles, source.short_title, "\\s#{stylesheet_codes['source_short_title']}")
              p(document, styles, formatted_source(source), "\\s#{stylesheet_codes['source_formatted_source']}")
            end
          end
        end
      end

      fond_printable_attributes.each do |attribute|
        methods = attribute.split('.')
        if fond.send(methods[0].to_sym).present? && fond.send(methods[0].to_sym) != 0
          strong(document, styles, Fond.human_attribute_name(methods[0]))
          index = "fond_#{methods[0]}"
          if attribute.include?('.')
            text = fond.send(methods[0].to_sym).send(methods[1].to_sym).to_s
          else
            text = fond.send(attribute.to_sym).to_s
          end
          p(document, styles, text, "\\s#{stylesheet_codes[index]}")
        end
      end

      if fond.sources.present?
        strong(document, styles, Source.human_name({:count => fond.sources.size}))
        fond.sources.each do |source|
          em(document, styles, source.short_title, "\\s#{stylesheet_codes['source_short_title']}")
          p(document, styles, formatted_source(source), "\\s#{stylesheet_codes['source_formatted_source']}")
        end
      end

      if fond.units.present?
        h2(document, styles, Unit.human_name({:count => fond.units.size}))
        fond.units.each do |unit|
          unit_printable_attributes.each do |attribute|
            methods = attribute.split('.')
            index = "unit_#{methods[0]}"
            if unit.send(methods[0].to_sym).present?
              if (methods[0] == 'title')
                h3(document, styles, unit.send(:formatted_title).to_s, "\\s#{stylesheet_codes[index]}")
              else
                strong(document, styles, Unit.human_attribute_name(methods[0]))
                if attribute.include?('.')
                  text = unit.send(methods[0].to_sym).send(methods[1].to_sym).to_s
                elsif attribute == 'sequence_number'
                  text = unit.display_sequence_number_from_hash(sequence_numbers).to_s
                else
                  text = unit.send(attribute.to_sym).to_s
                end
                p(document, styles, text, "\\s#{stylesheet_codes[index]}")
              end
            end
          end
        end
        my_page_break(document)
      end
    end

    File.open(tmp, 'w') do |file|
      file.write(document.to_rtf)
    end

    # A Windows non piacciono i file con encoding UTF-8 :-/
    content = File.read(tmp)

    File.open(self.dest_file, 'w') do |f|
      f.write(Iconv.iconv("LATIN1", "UTF-8", content))
    end

    File.delete(tmp)
  end

  def build_project_rtf_file
    tmp = "#{Rails.root}/tmp/tmp.rtf"

    project_fields = [
      "project_type",
      "display_date",
      "description"
    ]

    fond_fields = [
      "preferred_event.full_display_date",
      "extent",
      "description",
      "abstract",
      "access_condition",
      "access_condition_note",
    ]

    creator_fields = [
      "preferred_event.full_display_date",
      "history",
      "abstract"
    ]

    custodian_fields = [
      "history",
      "holdings",
      "collecting_policies",
      "accessibility",
      "services",
      "headquarter_address"
    ]
    project = Project.find(self.target_id, :include => [:project_managers, :project_stakeholders])
    all_fonds = project.fonds.roots.active(:include =>
        [:preferred_event, :other_names,
        [:custodians => [:preferred_name, :custodian_headquarter, :custodian_other_buildings, :sources]],
        [:creators => [:preferred_event, :preferred_name, :other_names, :sources]], :sources]
    )
    custodians = Array.new
    fonds = Hash.new {|h,k| h[k] = Array.new}
    creators = Hash.new {|h,k| h[k] = Array.new}
    sources = Array.new
    all_fonds.each do |fond|
      fond.sources.each do |source|
        sources.push(source)
      end
      fond.custodians.each do |custodian|
        custodian.sources.each do |source|
          sources.push(source)
        end
        custodians.push(custodian)
        fonds[custodian.id].push(fond)
        fond.creators.each do |creator|
          creators[fond.id].push(creator)
          creator.sources.each do |source|
            sources.push(source)
          end
        end
      end
    end
    custodians = custodians.uniq.sort{|a,b| a.display_name <=> b.display_name}
    sources = sources.uniq.sort{|a,b| a.short_title <=> b.short_title}
    fonds.each do |key, value|
      fonds[key] = value.uniq
    end
    creators.each do |key, value|
      creators[key] = value.uniq
    end

    styles = document_styles

    document_style = RTF::DocumentStyle.new()
    document_style.enable_facing_pages  = true
    document_style.enable_widow_control = true
    document_style.enable_title_page    = true

    document = Document.new(Font.new(Font::ROMAN, 'Times New Roman'), document_style)

    document.information.title = project.name
    document.information.author = "Archimista"

    document.store(CommandNode.new(document, "\\headerr\\pard\\qr\\plain\\f0\\fs18#{document.information.title}\\par", nil, false))
    document.store(CommandNode.new(document, "\\headerl\\pard\\ql\\plain\\f0\\fs18#{document.information.title}\\par", nil, false))
    document.store(CommandNode.new(document, "\\footerr\\pard\\qr\\plain\\f0\\fs18\\chpgn\\par", nil, false))
    document.store(CommandNode.new(document, "\\footerl\\pard\\ql\\plain\\f0\\fs18\\chpgn\\par", nil, false))

    document.store(CommandNode.new(self, "\\stylesheet#{stylesheet}", nil, false))

    title_page document, styles, "#{project.name}\n#{project.display_date}"

    h1(document, styles, project.name, "\\s#{stylesheet_codes['project_name']}")
    project_fields.each do |attribute|
      methods = attribute.split('.')
      index = "project_#{methods[0]}"
      if project.send(methods[0].to_sym).present?
        strong(document, styles, Project.human_attribute_name(methods[0].to_sym))
        if attribute.include?('.')
          text = project.send(methods[0].to_sym).send(methods[1].to_sym).to_s
        else
          text = project.send(attribute.to_sym).to_s
        end
        p(document, styles, text, "\\s#{stylesheet_codes[index]}")
      end
    end

    if project.project_managers.present?
      strong(document, styles, Project.human_attribute_name(:project_managers))
      elements = Array.new
      project.project_managers.each do |project_manager|
        text = Array.new
        text.push(project_manager.credit_name)
        text.push("[#{project_manager.qualifier}]") unless project_manager.qualifier.blank?
        elements.push(text.join(", "))
      end
      list document, elements, styles
    end

    if project.project_stakeholders.present?
      strong(document, styles, Project.human_attribute_name(:project_stakeholders))
      elements = Array.new
      project.project_stakeholders.each do |project_stakeholder|
        text = Array.new
        text.push(project_stakeholder.credit_name)
        text.push("[#{project_stakeholder.qualifier}]") unless project_stakeholder.qualifier.blank?
        elements.push(text.join(", "))
      end
      list document, elements, styles
    end

    custodians.each do |custodian|
      h1(document, styles, custodian.display_name, "\\s#{stylesheet_codes['custodian_display_name']}")
      custodian_fields.each do |attribute|
        methods = attribute.split('.')
        index = "custodian_#{methods[0]}"
        if custodian.send(methods[0].to_sym).present?
          strong(document, styles, Custodian.human_attribute_name(methods[0].to_sym))
          if attribute.include?('.')
            text = custodian.send(methods[0].to_sym).send(methods[1].to_sym).to_s
          else
            text = custodian.send(attribute.to_sym).to_s
          end
          p(document, styles, text, "\\s#{stylesheet_codes[index]}")
        end
      end

      if custodian.custodian_other_buildings.present?
        strong(document, styles, Custodian.human_attribute_name(:custodian_other_buildings))
        custodian.custodian_other_buildings.each do |building|
          text = formatted_custodian_building(building)
          text += " (#{building.custodian_building_type})" if building.custodian_building_type.present?
          p(document, styles, text)
          if building.description.present?
            text = "#{building.description}"
            p(document, styles, text)
          end
        end
      end
      if custodian.sources.present?
        strong(document, styles, Source.human_name({:count => custodian.sources.size}))
        p(document, styles, inline_short_sources(custodian.sources))
      end

      fonds[custodian.id].each do |fond|
        if creators[fond.id].present?
          creators[fond.id].each do |creator|
            h3(document, styles, creator.display_name, "\\s#{stylesheet_codes['creator_display_name']}")
            if creator.other_names.present?
              strong(document, styles, Creator.human_attribute_name(:other_names))
              creator.other_names.each do |name|
                text = name.name
                text += " (#{name.note})" if name.note.present?
                p(document, styles, text)
              end
            end
            creator_fields.each do |attribute|
              methods = attribute.split('.')
              index = "creator_#{methods[0]}"
              if creator.send(methods[0].to_sym).present?
                strong(document, styles,Creator.human_attribute_name(methods[0].to_sym))

                if attribute.include?('.')
                  text = creator.send(methods[0].to_sym).send(methods[1].to_sym).to_s
                else
                  text = creator.send(attribute.to_sym).to_s
                end
                p(document, styles, text, "\\s#{stylesheet_codes[index]}")
              end
            end
            if creator.sources.present?
              strong(document, styles,Source.human_name({:count => creator.sources.size}))
              p(document, styles, inline_short_sources(creator.sources))

            end
          end
        else
          h3(document, styles, "Nessun produttore presente", "\\s#{stylesheet_codes['creator_display_name']}")
        end

        h4(document, styles, fond.name, "\\s#{stylesheet_codes['fond_name']}")
        if fond.other_names.present?
          strong(document, styles, Fond.human_attribute_name(:other_names))
          fond.other_names.each do |name|
            text= name.name
            text += "( #{name.note})" if name.note.present?
            p(document, styles, text)
          end
        end

        fond_fields.each do |attribute|
          methods = attribute.split('.')
          index = "fond_#{methods[0]}"
          if fond.send(methods[0].to_sym).present?
            strong(document, styles, Fond.human_attribute_name(methods[0].to_sym))

            if attribute.include?('.')
              text = fond.send(methods[0].to_sym).send(methods[1].to_sym).to_s
            else
              text = fond.send(attribute.to_sym).to_s
            end
            p(document, styles, text, "\\s#{stylesheet_codes[index]}")
          end
        end
        if fond.sources.present?
          strong(document, styles, Source.human_name({:count => fond.sources.size}))
          p(document, styles, inline_short_sources(fond.sources))
        end
      end
    end

    if sources.present?
      h2(document, styles, Source.human_name({:count => sources.size}))
      sources.each do |source|
        p(document, styles, "[#{source.short_title}] #{formatted_source(source)}", "\\s#{stylesheet_codes['source_formatted_source']}")
      end
    end

    File.open(tmp, 'w') do |file|
      file.write(document.to_rtf)
    end

    # A Windows non piacciono i file con encoding UTF-8 :-/
    content = File.read(tmp)

    File.open(self.dest_file, 'w') do |f|
      f.write(Iconv.iconv("LATIN1", "UTF-8", content))
    end

    File.delete(tmp)
  end

  def build_custodian_rtf_file
    tmp = "#{Rails.root}/tmp/tmp.rtf"

    project_fields = [
      "project_type",
      "display_date",
      "description"
    ]

    fond_fields = [
      "preferred_event.full_display_date",
      "extent",
      "description",
      "abstract",
      "access_condition",
      "access_condition_note",
    ]

    creator_fields = [
      "preferred_event.full_display_date",
      "history",
      "abstract"
    ]

    custodian_fields = [
      "history",
      "holdings",
      "collecting_policies",
      "accessibility",
      "services",
      "headquarter_address"
    ]
    custodian = Custodian.find(self.target_id, :include => [:preferred_name, :custodian_headquarter, :custodian_other_buildings, :sources])
    all_fonds = custodian.fonds.roots.active(:include =>
        [:preferred_event, :other_names,
        [:projects => [:project_managers, :project_stakeholders]],
        [:creators => [:preferred_event, :preferred_name, :other_names, :sources]], :sources]
    )
    projects = Array.new
    fonds = Hash.new {|h,k| h[k] = Array.new}
    creators = Hash.new {|h,k| h[k] = Array.new}
    sources = Array.new
    all_fonds.each do |fond|
      fond.sources.each do |source|
        sources.push(source)
      end
      fond.projects.each do |project|
        projects.push(project)
        fonds[project.id].push(fond)
        fond.creators.each do |creator|
          creators[fond.id].push(creator)
          creator.sources.each do |source|
            sources.push(source)
          end
        end
      end
    end
    projects = projects.uniq
    sources = sources.uniq.sort{|a,b| a.short_title <=> b.short_title}
    fonds.each do |key, value|
      fonds[key] = value.uniq
    end
    creators.each do |key, value|
      creators[key] = value.uniq
    end

    styles = document_styles

    document_style = RTF::DocumentStyle.new()
    document_style.enable_facing_pages  = true
    document_style.enable_widow_control = true
    document_style.enable_title_page    = true

    document = Document.new(Font.new(Font::ROMAN, 'Times New Roman'), document_style)

    document.information.title = custodian.display_name
    document.information.author = "Archimista"

    document.store(CommandNode.new(document, "\\headerr\\pard\\qr\\plain\\f0\\fs18#{document.information.title}\\par", nil, false))
    document.store(CommandNode.new(document, "\\headerl\\pard\\ql\\plain\\f0\\fs18#{document.information.title}\\par", nil, false))
    document.store(CommandNode.new(document, "\\footerr\\pard\\qr\\plain\\f0\\fs18\\chpgn\\par", nil, false))
    document.store(CommandNode.new(document, "\\footerl\\pard\\ql\\plain\\f0\\fs18\\chpgn\\par", nil, false))

    document.store(CommandNode.new(self, "\\stylesheet#{stylesheet}", nil, false))

    title_page document, styles, "#{custodian.display_name}"

    h1(document, styles, custodian.display_name, "\\s#{stylesheet_codes['custodian_display_name']}")
    custodian_fields.each do |attribute|
      methods = attribute.split('.')
      index = "custodian_#{methods[0]}"
      if custodian.send(methods[0].to_sym).present?
        strong(document, styles, Custodian.human_attribute_name(methods[0].to_sym))
        if attribute.include?('.')
          text = custodian.send(methods[0].to_sym).send(methods[1].to_sym).to_s
        else
          text = custodian.send(attribute.to_sym).to_s
        end
        p(document, styles, text, "\\s#{stylesheet_codes[index]}")
      end
    end

    if custodian.custodian_other_buildings.present?
      strong(document, styles, Custodian.human_attribute_name(:custodian_other_buildings))
      custodian.custodian_other_buildings.each do |building|
        text = formatted_custodian_building(building)
        text += " (#{building.custodian_building_type})" if building.custodian_building_type.present?
        p(document, styles, text)
        if building.description.present?
          text = "#{building.description}"
          p(document, styles, text)
        end
      end
    end

    if custodian.sources.present?
      strong(document, styles, Source.human_name({:count => custodian.sources.size}))
      p(document, styles, inline_short_sources(custodian.sources))
    end

    projects.each do |project|
      h1(document, styles, project.name, "\\s#{stylesheet_codes['project_name']}")
      project_fields.each do |attribute|
        methods = attribute.split('.')
        index = "project_#{methods[0]}"
        if project.send(methods[0].to_sym).present?
          strong(document, styles, Project.human_attribute_name(methods[0].to_sym))
          if attribute.include?('.')
            text = project.send(methods[0].to_sym).send(methods[1].to_sym).to_s
          else
            text = project.send(attribute.to_sym).to_s
          end
          p(document, styles, text, "\\s#{stylesheet_codes[index]}")
        end
      end

      if project.project_managers.present?
        strong(document, styles, Project.human_attribute_name(:project_managers))
        elements = Array.new
        project.project_managers.each do |project_manager|
          text = Array.new
          text.push(project_manager.credit_name)
          text.push("[#{project_manager.qualifier}]") unless project_manager.qualifier.blank?
          elements.push(text.join(", "))
        end
        list document, elements, styles
      end

      if project.project_stakeholders.present?
        strong(document, styles, Project.human_attribute_name(:project_stakeholders))
        elements = Array.new
        project.project_stakeholders.each do |project_stakeholder|
          text = Array.new
          text.push(project_stakeholder.credit_name)
          text.push("[#{project_stakeholder.qualifier}]") unless project_stakeholder.qualifier.blank?
          elements.push(text.join(", "))
        end
        list document, elements, styles
      end

      fonds[project.id].each do |fond|
        if creators[fond.id].present?
          creators[fond.id].each do |creator|
            h3(document, styles, creator.display_name, "\\s#{stylesheet_codes['creator_display_name']}")
            if creator.other_names.present?
              strong(document, styles, Creator.human_attribute_name(:other_names))
              creator.other_names.each do |name|
                text = name.name
                text += "( #{name.note})" if name.note.present?
                p(document, styles, text)
              end
            end
            creator_fields.each do |attribute|
              methods = attribute.split('.')
              index = "creator_#{methods[0]}"
              if creator.send(methods[0].to_sym).present?
                strong(document, styles,Creator.human_attribute_name(methods[0].to_sym))

                if attribute.include?('.')
                  text = creator.send(methods[0].to_sym).send(methods[1].to_sym).to_s
                else
                  text = creator.send(attribute.to_sym).to_s
                end
                p(document, styles, text, "\\s#{stylesheet_codes[index]}")
              end
            end
            if creator.sources.present?
              strong(document, styles,Source.human_name({:count => creator.sources.size}))
              p(document, styles, inline_short_sources(creator.sources))

            end
          end
        else
          h3(document, styles, "Nessun produttore presente", "\\s#{stylesheet_codes['creator_display_name']}")
        end

        h4(document, styles, fond.name, "\\s#{stylesheet_codes['fond_name']}")
        if fond.other_names.present?
          strong(document, styles, Fond.human_attribute_name(:other_names))
          fond.other_names.each do |name|
            text= name.name
            text += " (#{name.note})" if name.note.present?
            p(document, styles, text)
          end
        end

        fond_fields.each do |attribute|
          methods = attribute.split('.')
          index = "fond_#{methods[0]}"
          if fond.send(methods[0].to_sym).present?
            strong(document, styles, Fond.human_attribute_name(methods[0].to_sym))

            if attribute.include?('.')
              text = fond.send(methods[0].to_sym).send(methods[1].to_sym).to_s
            else
              text = fond.send(attribute.to_sym).to_s
            end
            p(document, styles, text, "\\s#{stylesheet_codes[index]}")
          end
        end
        if fond.sources.present?
          strong(document, styles, Source.human_name({:count => fond.sources.size}))
          p(document, styles, inline_short_sources(fond.sources))
        end
      end
    end

    if sources.present?
      h2(document, styles, Source.human_name({:count => sources.size}))
      sources.each do |source|
        p(document, styles, "[#{source.short_title}] #{formatted_source(source)}", "\\s#{stylesheet_codes['source_formatted_source']}")
      end
    end

    File.open(tmp, 'w') do |file|
      file.write(document.to_rtf)
    end

    # A Windows non piacciono i file con encoding UTF-8 :-/
    content = File.read(tmp)

    File.open(self.dest_file, 'w') do |f|
      f.write(Iconv.iconv("LATIN1", "UTF-8", content))
    end

    File.delete(tmp)
  end

  private

  def strong document, styles, string, stylesheet_code='\\s15'
    document.paragraph(styles['P']) do |p|
      p.store(CommandNode.new(self, stylesheet_code, nil, false, false))
      p.apply(styles['STRONG']) do |t|
        t << string
      end
    end
  end

  def em document, styles, string, stylesheet_code=nil
    document.paragraph(styles['P']) do |p|
      p.store(CommandNode.new(self, stylesheet_code, nil, false, false)) unless stylesheet_code.nil?
      p.apply(styles['EM']) do |t|
        t << string
      end
    end
  end

  def title_page document, styles, string, stylesheet_code=nil
    tokens = string.split("\n")
    document.paragraph(styles['TITLE']) do |p|
      p.store(CommandNode.new(self, stylesheet_code, nil, false, false)) unless stylesheet_code.nil?
      p.apply(styles['TITLE_DEFAULT']) do |t|
        tokens.each do |token|
          unless token.empty?
            t << token.strip
            t.line_break
          end
        end
      end
    end
    my_page_break document
  end

  def h1 document, styles, string, stylesheet_code=nil
    document.paragraph(styles['P']) do |p|
      p.store(CommandNode.new(self, stylesheet_code, nil, false, false)) unless stylesheet_code.nil?
      p.apply(styles['H1']) do |t|
        t << string
        t.line_break
      end
    end
  end

  def h2 document, styles, string, stylesheet_code=nil
    document.paragraph(styles['P']) do |p|
      p.store(CommandNode.new(document, stylesheet_code, nil, false, false)) unless stylesheet_code.nil?
      p.apply(styles['H2']) do |t|
        t << string
      end
    end
    document.line_break
  end

  def h3 document, styles, string, stylesheet_code=nil
    document.paragraph(styles['P']) do |p|
      p.store(CommandNode.new(document, stylesheet_code, nil, false, false)) unless stylesheet_code.nil?
      p.apply(styles['H3']) do |t|
        t << string
      end
    end
    document.line_break
  end

  def h4 document, styles, string, stylesheet_code=nil
    document.paragraph(styles['P']) do |p|
      p.store(CommandNode.new(self, stylesheet_code, nil, false, false)) unless stylesheet_code.nil?
      p.apply(styles['H4']) do |t|
        t << string
      end
    end
    document.line_break
  end

  def p document, styles, string, stylesheet_code=nil
    parser = Parser.new(string)
    nodes = parser.parse
    nodes.each do |node|
      case node.type
      when 'text'
        document.paragraph(styles['P']) do |p|
          p.store(CommandNode.new(document, stylesheet_code, nil, false, false)) unless stylesheet_code.nil?
          p.apply(styles['DEFAULT']) do |t|
            t << node.content
            t.line_break
          end
        end
      when 'ordered_list'
        list(document, node.content, styles, :decimal)
      when 'unordered_list'
        list(document, node.content, styles)
      end
    end
  end

  # La documentazione sembra essere ambigua su \page e \pard \insrsid \page \par
  # Word comunque riconosce \pard \insrsid \page \par come interruzione pagina
  # Wordpad nessuna delle due :-|
  def my_page_break document
    document.store(CommandNode.new(document, '\pard \insrsid \page \par', nil, false))
    nil
  end

  def turn_on_page_numbering document
    document.store(CommandNode.new(document, '\header\pard\qr\plain\f0\chpgn\par', nil, false))
    nil
  end

  def draw_line document
    document.store(CommandNode.new(document, '\pard \brdrb \brdrs\brdrw10\brsp20 {\fs4\~}\par \pard', nil, false))
    document.line_break
    nil
  end

  def list(document, elements, styles, kind=:bullets)
    document.list(kind) do |ul|
      elements.each do |element|
        ul.item do |li|
          li.apply(styles['DEFAULT']){|x| x << element}
        end
      end
    end
    nil
  end

  def formatted_source(source)
    if source.use_legacy?
      source.legacy_description.gsub(/<C>|<N>|<T>|<CR>/i, '')
    else
      [
        source.author,
        (source.title.present? ? source.title : nil),
        source.publisher,
        source.date_string
      ].
        delete_if{|fragment| fragment.blank?}.
        join(", ")
    end
  end

  def formatted_editor(editor)
    [
      editor.name,
      (editor.qualifier.present? ? editor.qualifier : nil),
      (editor.editing_type.present? ? editor.editing_type : nil)
    ].
      delete_if{|fragment| fragment.blank?}.
      join(", ")
  end

  def inline_short_sources(sources)
    text = Array.new
    sources.each do |source|
      text.push("[#{source.short_title}]")
    end
    text.join(", ")
  end

  def formatted_custodian_building(building)
    [
      building.address,
      building.postcode,
      building.city,
      building.country
    ].
      delete_if{|fragment| fragment.blank?}.
      join(" ")
  end

  def translate_value(value)
    I18n::translate(value)
  end


end


