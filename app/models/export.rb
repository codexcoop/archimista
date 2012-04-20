class Export < ActiveRecord::Base
  # See: http://railscasts.com/episodes/193-tableless-model
  # See: http://codetunes.com/2008/07/20/tableless-models-in-rails
  require 'zip/zip'

  TMP_EXPORTS = "#{Rails.root}/tmp/exports"

  def self.columns() @columns ||= []; end

  def self.column(name, sql_type = nil, default = nil, null = true)
    columns << ActiveRecord::ConnectionAdapters::Column.new(name.to_s, default, sql_type.to_s, null)
  end

  column :metadata_file, :string
  column :data_file, :string
  column :dest_file, :string
  column :target_id, :integer
  column :group_id, :integer

  attr_accessor :fond_ids, :unit_ids, :creator_ids, :custodian_ids, :document_form_ids, :project_ids, :institution_ids, :source_ids, :group_id

  def tables
    {
      :fonds => ["fond_events", "fond_identifiers", "fond_langs", "fond_names", "fond_owners", "fond_urls", "fond_editors"],
      :units => ["unit_events", "unit_identifiers","unit_damages", "unit_langs", "unit_other_reference_numbers", "unit_urls", "unit_editors", "iccd_authors", "iccd_descriptions", "iccd_tech_specs", "iccd_damages", "iccd_subjects"],
      :creators => ["creator_events", "creator_identifiers","creator_legal_statuses", "creator_names", "creator_urls", "creator_activities", "creator_editors"],
      :custodians => ["custodian_buildings", "custodian_contacts","custodian_identifiers", "custodian_names", "custodian_owners", "custodian_urls", "custodian_editors"],
      :projects => ["project_credits", "project_urls"],
      :sources => ["source_urls"],
      :institutions => ["institution_editors"],
      :headings => [],
      :editors => [],
      :document_forms => ["document_form_editors"],
      :digital_objects => []
    }
  end

  def fonds_and_units
    fonds = Fond.subtree_of(self.target_id).all(:include => [:units], :order => "sequence_number")
    self.unit_ids = Array.new
    self.fond_ids = fonds.map(&:id).join(',')

    File.open(self.data_file, "a") do |file|
      fonds.each do |fond|
        fond.legacy_id = fond.id
        if fond.is_root?
          fond.legacy_parent_id = nil
        else
          fond.legacy_parent_id = fond.parent_id.to_s
        end
        file.write(fond.to_json(:except => [:id, :ancestry, :group_id, :db_source, :created_by, :updated_by, :created_at, :updated_at]).gsub("\\r",""))
        file.write("\r\n")

        fond.units.each do |unit|
          unit.legacy_id = unit.id
          if unit.is_root?
            unit.legacy_parent_unit_id = nil
          else
            unit.legacy_parent_unit_id = unit.parent_id.to_s
          end
          unit.legacy_root_fond_id = unit.root_fond_id
          unit.legacy_parent_fond_id = unit.fond_id
          file.write(unit.to_json(:except => [:id, :ancestry, :db_source, :created_by, :updated_by, :created_at, :updated_at]).gsub("\\r",""))
          file.write("\r\n")
          self.unit_ids.push(unit.id)
        end
      end

      unless self.fond_ids.empty?
        self.tables[:fonds].each do |table|
          model = table.singularize.camelize.constantize
          set = model.all(:conditions => "fond_id IN (#{self.fond_ids})")
          set.each do |e|
            e.legacy_id = e.fond_id
            file.write(e.to_json(:except => [:id, :db_source, :created_at, :updated_at]))
            file.write("\r\n")
          end
        end
      end

      #TODO considerare each_slice su unit_ids per grandi quantitativi di unità (+query ma meno memoria).
      unless self.unit_ids.empty?
        self.tables[:units].each do |table|
          model = table.singularize.camelize.constantize
          set = model.all(:conditions => "unit_id IN (#{self.unit_ids.join(',')})")
          set.each do |e|
            e.legacy_id = e.unit_id
            file.write(e.to_json(:except => [:id, :db_source, :created_at, :updated_at]))
            file.write("\r\n")
          end
        end
      end
    end
  end

  def major_entities
    entities = ['creator', 'custodian', 'project']
    File.open(self.data_file, "a") do |file|
      entities.each do |entity|
        container = Array.new
        relation = "rel_#{entity}_fond".camelize.constantize
        model = entity.camelize.constantize
        index = entity.pluralize.to_sym

        set = relation.all(:conditions => "fond_id IN (#{self.fond_ids})")
        set.each do |rel|
          container.push rel.send("#{entity}_id")
          rel.legacy_fond_id = rel.fond_id
          rel.send("legacy_#{entity}_id=", rel.send("#{entity}_id"))
          file.write(rel.to_json(:except => [:id, :db_source, :fond_id, "#{entity}_id".to_sym, :created_at, :updated_at]))
          file.write("\r\n")
        end

        if entity == 'creator'
          direct_creators = container.join(',')
          unless direct_creators.blank?
            set = RelCreatorCreator.all(:conditions => "creator_id IN (#{direct_creators}) OR related_creator_id IN (#{direct_creators})")
            set.each do |rel|
              rel.legacy_creator_id = rel.creator_id
              rel.legacy_related_creator_id = rel.related_creator_id
              file.write(rel.to_json(:except => [:id, :db_source, :creator_id, :related_creator_id, :created_at, :updated_at]))
              file.write("\r\n")
              container.push(rel.creator_id)
              container.push(rel.related_creator_id)
            end
          end
        end

        ids = container.uniq.join(',')
        unless ids.blank?
          set = model.all(:conditions => "id IN (#{ids})")
          set.each do |ent|
            ent.legacy_id = ent.id
            file.write(ent.to_json(:except => [:id, :group_id, :db_source, :created_by, :updated_by, :created_at, :updated_at]))
            file.write("\r\n")
          end

          self.tables[index].each do |table|
            attached_model = table.singularize.camelize.constantize
            set = attached_model.all(:conditions => "#{entity}_id IN (#{ids})")
            set.each do |e|
              e.legacy_id = e.send("#{entity}_id")
              file.write(e.to_json(:except => [:id, :db_source, :created_at, :updated_at]))
              file.write("\r\n")
            end
          end
        end
        self.send("#{entity}_ids=", container.uniq)
      end
    end
  end

  def institutions
    i = Array.new
    unless self.creator_ids.blank?
      File.open(self.data_file, "a") do |file|
        set = RelCreatorInstitution.all(:conditions => "creator_id IN (#{self.creator_ids.join(',')})")
        set.each do |rel|
          rel.legacy_creator_id = rel.creator_id
          rel.legacy_institution_id = rel.institution_id
          file.write(rel.to_json(:except => [:id, :db_source, :created_at, :updated_at]))
          file.write("\r\n")
          i.push(rel.institution_id)
        end

        self.institution_ids = i.uniq
        unless self.institution_ids.blank?
          set = Institution.all(:conditions => "id IN (#{self.institution_ids.join(',')})")
          set.each do |institution|
            institution.legacy_id = institution.id
            file.write(institution.to_json(:except => [:id, :db_source, :group_id, :created_by, :updated_by, :created_at, :updated_at]))
            file.write("\r\n")
          end

          self.tables[:institutions].each do |table|
            model = table.singularize.camelize.constantize
            set = model.all(:conditions => "institution_id IN (#{self.institution_ids.join(',')})")
            set.each do |e|
              e.legacy_id = e.institution_id
              file.write(e.to_json(:except => [:id, :db_source, :created_at, :updated_at]))
              file.write("\r\n")
            end
          end

        end
      end
    end
  end

  def headings
    entities = ['fond', 'unit']
    container = Array.new

    File.open(self.data_file, "a") do |file|
      entities.each do |entity|
        relation = "rel_#{entity}_heading".camelize.constantize
        ids = self.send("#{entity}_ids")
        ids = ids.join(',') unless entity == 'fond'
        unless ids.blank?
          set = relation.all(:conditions => "#{entity}_id IN (#{ids})")
          set.each do |rel|
            rel.send("legacy_#{entity}_id=", rel.send("#{entity}_id"))
            rel.legacy_heading_id = rel.heading_id
            file.write(rel.to_json(:except => [:id, :db_source,:source_id, "#{entity}_id".to_sym, :created_at, :updated_at]))
            file.write("\r\n")
            container.push(rel.heading_id)
          end
        end
      end

      headings = container.uniq
      unless headings.blank?
        set = Heading.all(:conditions => "id IN (#{headings.join(',')})")
        set.each do |heading|
          heading.legacy_id = heading.id
          file.write(heading.to_json(:except => [:id, :db_source, :group_id, :created_at, :updated_at]))
          file.write("\r\n")
        end
      end
    end
  end

  def document_forms
    df = Array.new
    File.open(self.data_file, "a") do |file|
      set = RelFondDocumentForm.all(:conditions => "fond_id IN (#{self.fond_ids})")
      set.each do |rel|
        rel.legacy_fond_id = rel.fond_id
        rel.legacy_document_form_id = rel.document_form_id
        file.write(rel.to_json(:except => [:id, :db_source, :created_at, :updated_at]))
        file.write("\r\n")
        df.push(rel.document_form_id)
      end

      self.document_form_ids = df.uniq
      unless self.document_form_ids.blank?
        set = DocumentForm.all(:conditions => "id IN (#{self.document_form_ids.join(',')})")
        set.each do |document_form|
          document_form.legacy_id = document_form.id
          file.write(document_form.to_json(:except => [:id, :db_source, :created_by, :updated_by, :group_id, :created_at, :updated_at]))
          file.write("\r\n")
        end

        self.tables[:document_forms].each do |table|
          model = table.singularize.camelize.constantize
          set = model.all(:conditions => "document_form_id IN (#{self.document_form_ids.join(',')})")
          set.each do |e|
            e.legacy_id = e.document_form_id
            file.write(e.to_json(:except => [:id, :db_source, :created_at, :updated_at]))
            file.write("\r\n")
          end
        end
      end
    end
  end

  def sources
    entities = ['creator', 'custodian', 'fond', 'unit']
    container = Array.new

    File.open(self.data_file, "a") do |file|
      entities.each do |entity|
        relation = "rel_#{entity}_source".camelize.constantize
        ids = self.send("#{entity}_ids")
        ids = ids.join(',') unless entity == 'fond'
        unless ids.blank?
          set = relation.all(:conditions => "#{entity}_id IN (#{ids})")
          set.each do |rel|
            rel.send("legacy_#{entity}_id=", rel.send("#{entity}_id"))
            rel.legacy_source_id = rel.source_id
            file.write(rel.to_json(:except => [:id, :db_source,:source_id, "#{entity}_id".to_sym, :created_at, :updated_at]))
            file.write("\r\n")
            container.push(rel.source_id)
          end
        end
      end

      self.source_ids = container.uniq
      unless self.source_ids.blank?
        set = Source.all(:conditions => "id IN (#{self.source_ids.join(',')})")
        set.each do |source|
          source.legacy_id = source.id
          file.write(source.to_json(:except => [:id, :db_source, :created_by, :updated_by, :group_id, :created_at, :updated_at]))
          file.write("\r\n")
        end

        self.tables[:sources].each do |table|
          model = table.singularize.camelize.constantize
          set = model.all(:conditions => "source_id IN (#{self.source_ids.join(',')})")
          set.each do |e|
            e.legacy_id = e.source_id
            file.write(e.to_json(:except => [:id, :db_source, :created_at, :updated_at]))
            file.write("\r\n")
          end
        end
      end
    end
  end

  def editors
    File.open(self.data_file, "a") do |file|
      set = Editor.all(:conditions => "group_id = #{self.group_id}")
      set.each do |editor|
        editor.legacy_id = editor.id
        file.write(editor.to_json(:except => [:id, :db_source, :group_id, :created_at, :updated_at]))
        file.write("\r\n")
      end
    end
  end

  def digital_objects
    entities = {
      'Fond' => self.fond_ids,
      'Unit' => self.unit_ids,
      'Creator' => self.creator_ids,
      'Custodian' => self.custodian_ids,
      'Source' => self.source_ids
    }
    File.open(self.data_file, "a") do |file|
      entities.each do |type, ids|
        unless ids.blank?
          ids = ids.join(',') unless type == 'Fond'
          set = DigitalObject.all(:conditions => "attachable_id IN (#{ids}) AND attachable_type = '#{type}'")
          set.each do |digital_object|
            digital_object.legacy_id = digital_object.attachable_id
            file.write(digital_object.to_json(:except => [:id, :group_id, :db_source, :created_by, :updated_by, :created_at, :updated_at]))
            file.write("\r\n")
          end
        end
      end
    end
  end

  def create_export_file
    create_data_file
    create_metadata_file
    files = {"metadata.json" => self.metadata_file, "data.json" => self.data_file}
    Zip::ZipFile.open(self.dest_file, Zip::ZipFile::CREATE) do |zipfile|
      files.each do |dst, src|
        zipfile.add(dst, src)
      end
    end
  end

  private

  def create_metadata_file
    metadata = Hash.new
    metadata.store('version', APP_VERSION.gsub('.', '').to_i)
    metadata.store('checksum', Digest::SHA256.file(self.data_file).hexdigest)
    metadata.store('date', Time.now)
    metadata.store('producer', Config::CONFIG['host'])
    File.open(self.metadata_file, "w+") do |file|
      file.write(metadata.to_json)
    end
  end

  def create_data_file
    @fond = Fond.find(self.target_id)
    if @fond
      ActiveRecord::Base.include_root_in_json = true
      fonds_and_units
      major_entities
      headings
      document_forms
      institutions
      sources
      #editors
      digital_objects
    end
  end

end