class RtfBuilder < ActiveRecord::Base
  # See: http://railscasts.com/episodes/193-tableless-model
  # See: http://codetunes.com/2008/07/20/tableless-models-in-rails

  def self.columns() @columns ||= []; end

  def self.column(name, sql_type = nil, default = nil, null = true)
    columns << ActiveRecord::ConnectionAdapters::Column.new(name.to_s, default, sql_type.to_s, null)
  end

  column :dest_file, :string
  column :target_id, :integer

  def build_rtf_file
    fonds = Fond.subtree_of(self.target_id).active.all(
      :include => [:preferred_event, [:units => :preferred_event]],
      :order => "sequence_number")

    tmp = "#{Rails.root}/tmp/tmp.rtf"

    styles = {}

    styles['BOLD'] = CharacterStyle.new
    styles['BOLD'].bold      = true
    styles['BOLD'].font_size = 20

    styles['DEFAULT'] = CharacterStyle.new
    styles['DEFAULT'].font_size = 20

    styles['NORMAL'] = ParagraphStyle.new
    styles['NORMAL'].justification = ParagraphStyle::LEFT_JUSTIFY

    styles['COUNTER'] = ParagraphStyle.new
    styles['COUNTER'].justification = ParagraphStyle::RIGHT_JUSTIFY

    stylesheet = String.new
    stylesheet << '{\s15\widctlpar \f0\fs20\lang1040 \sbasedon0\snext15 Intestazione;}'
    stylesheet << '{\s16\widctlpar \f0\fs20\lang1040 \sbasedon0\snext16 Tipologia fondo;}'
    stylesheet << '{\s17\widctlpar \f0\fs20\lang1040 \sbasedon0\snext17 Denominazione fondo;}'
    stylesheet << '{\s18\widctlpar \f0\fs20\lang1040 \sbasedon0\snext18 Cronologia fondo;}'
    stylesheet << '{\s19\widctlpar \f0\fs20\lang1040 \sbasedon0\snext19 Abstract fondo;}'
    stylesheet << '{\s20\widctlpar \f0\fs20\lang1040 \sbasedon0\snext20 Profilo storico fondo;}'
    stylesheet << '{\s21\widctlpar \f0\fs20\lang1040 \sbasedon0\snext21 Descrizione fondo;}'
    stylesheet << '{\s22\widctlpar \f0\fs20\lang1040 \sbasedon0\snext22 Titolo unità;}'
    stylesheet << '{\s23\widctlpar \f0\fs20\lang1040 \sbasedon0\snext23 Cronologia unità;}'
    stylesheet << '{\s24\widctlpar \f0\fs20\lang1040 \sbasedon0\snext24 Contenuto unità;}'
    stylesheet << '{\s25\widctlpar \f0\fs20\lang1040 \sbasedon0\snext25 Note unità;}'
    stylesheet << '{\s26\widctlpar \f0\fs20\lang1040 \sbasedon0\snext26 Segnatura unità;}'
    stylesheet << '{\s27\widctlpar \f0\fs20\lang1040 \sbasedon0\snext27 Numero unità;}'

    document = Document.new(Font.new(Font::ROMAN, 'Times New Roman'))
    document.store(CommandNode.new(self, "\\stylesheet#{stylesheet}", nil, false))
    counter = 1

    fonds.each do |fond|
      print_counter(document, styles, counter)
      counter += 1

      if fond.fond_type.present?
        print_header(document, styles, 'Tipologia')
        print_short_content(document, styles, fond.fond_type.capitalize!, '\s16')
      end

      print_header(document, styles, 'Denominazione completa')
      print_short_content(document, styles, fond.name, '\s17')

      if fond.preferred_event.present?
        print_header(document, styles, 'Estremi cronologici')
        print_short_content(document, styles, fond.preferred_event.full_display_date, '\s18')
      end

      if fond.abstract.present?
        print_header(document, styles, 'Abstract')
        print_long_content(document, styles, fond.abstract, '\s19')
      end

      if fond.history.present?
        print_header(document, styles, 'Profilo storico biografico')
        print_long_content(document, styles, fond.history, '\s20')
      end

      if fond.description.present?
        print_header(document, styles, 'Descrizione')
        print_long_content(document, styles, fond.description, '\s21')
      end

      if fond.units.present?
        fond.units.each do |unit|
          print_counter(document, styles, counter)
          counter += 1
          print_header(document, styles, 'Numero unità')
          print_short_content(document, styles, unit.sequence_number.to_s, '\s27')

          print_header(document, styles, 'Titolo')
          print_short_content(document, styles, unit.title,'\s22')

          if unit.preferred_event.present?
            print_header(document, styles, 'Estremi cronologici')
            print_short_content(document, styles, unit.preferred_event.full_display_date, '\s23')
          end

          if unit.content.present?
            print_header(document, styles, 'Contenuto')
            print_long_content(document, styles, unit.content, '\s24')
          end

          if unit.note.present?
            print_header(document, styles, 'Note complessive')
            print_long_content(document, styles, unit.note, '\s25')
          end

          if unit.reference_number.present?
            print_header(document, styles, 'Segnatura definitiva')
            print_short_content(document, styles, unit.reference_number, '\s26')
          end

        end
      end
      my_page_break(document)
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
  def print_counter document, styles, index
    document.paragraph(styles['COUNTER']) do |p|
      p.apply(styles['DEFAULT']) do |t|
        t << "(#{index.to_s})"
      end
    end
  end

  def print_header document, styles, string, stylesheet_code='\s15'
    document.paragraph(styles['NORMAL']) do |p|
      p.store(CommandNode.new(self, stylesheet_code, nil, false,false))
      p.apply(styles['BOLD']) do |t|
        t << string
      end
    end
  end

  def print_short_content document, styles, string, stylesheet_code=nil
    document.paragraph(styles['NORMAL']) do |p|
      p.store(CommandNode.new(self, stylesheet_code, nil, false,false)) unless stylesheet_code.nil?
      p.apply(styles['DEFAULT']) do |t|
        t << string
        t.line_break
      end
    end
  end

  def print_long_content document, styles, string, stylesheet_code=nil
    tokens = string.split("\n")
    document.paragraph(styles['NORMAL']) do |p|
      p.store(CommandNode.new(self, stylesheet_code, nil, false,false)) unless stylesheet_code.nil?
      p.apply(styles['DEFAULT']) do |t|
        tokens.each do |token|
          unless token.empty?
            t << token.strip
            t.line_break
          end
        end
      end
    end
  end

  # La documentazione sembra essere ambigua su \page e \pard \insrsid \page \par
  # Word comunque riconosce \pard \insrsid \page \par come interruzione pagina
  # Wordpad nessuna delle due :-|
  def my_page_break document
    document.store(CommandNode.new(self, '\pard \insrsid \page \par', nil, false))
    nil
  end

end
