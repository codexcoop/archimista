class Import < ActiveRecord::Base
  require 'zip/zip'

  TMP_IMPORTS = "#{Rails.root}/tmp/imports"

  belongs_to :user
  belongs_to :importable, :polymorphic => true

  has_attached_file :data,
    :path => ":rails_root/public/imports/:id/:basename.:extension"

  before_create :sanitize_file_name
  validates_attachment_presence :data

  def ar_connection
    ActiveRecord::Base.connection
  end

  def adapter
    ar_connection.adapter_name.downcase
  end

  def data_file
    TMP_IMPORTS + "/#{self.id}_data.json"
  end

  def metadata_file
    TMP_IMPORTS + "/#{self.id}_metadata.json"
  end

  def delete_tmp_files
    File.delete(data_file)      if File.exists?(data_file)
    File.delete(metadata_file)  if File.exists?(metadata_file)
  end

  def db_has_subunits?
    Unit.exists?(["db_source = ? AND ancestry_depth > 0", self.identifier])
  end

  def db_has_digital_objects?
    DigitalObject.exists?(["db_source = ?", self.identifier])
  end

  def import_aef_file(user)
    File.open(data_file) do |file|
      begin
        ActiveRecord::Base.transaction do
          lines = file.enum_for(:each_line)
          lines.each do |line|
            next if line.blank?
            data = ActiveSupport::JSON.decode(line.strip)
            key = data.keys.first
            model = key.camelize.constantize
            object = model.new(data[key])
            object.db_source = self.identifier
            object.group_id = user.group_id if object.has_attribute? 'group_id'
            object.created_by = user.id if object.has_attribute? 'created_by'
            object.updated_by = user.id if object.has_attribute? 'updated_by'
            object.send(:create_without_callbacks)
          end
        end
        update_statements
        return true
      rescue
        return false
      ensure
        file.close
      end
    end
  end

  def update_statements
    begin
      ActiveRecord::Base.transaction do
        update_fonds_ancestry
        update_units_fond_id
        update_subunits_ancestry if db_has_subunits?
        update_one_to_many_relations
        update_many_to_many_relations
        update_digital_objects if db_has_digital_objects?
        if self.importable_type == 'Fond'
          self.importable_id = Fond.find_by_db_source_and_ancestry("#{self.identifier}", nil).id
        else
          self.importable_id = self.importable_type.constantize.find_by_db_source("#{self.identifier}").id
        end
      end
    end
  end

  def update_fonds_ancestry(parent_id = nil, ancestry = nil)
    Fond.find_each(:conditions => {:legacy_parent_id => parent_id, :db_source => self.identifier}) do |node|
      node.without_ancestry_callbacks do
        node.update_attribute :ancestry, ancestry
      end
      update_fonds_ancestry node.legacy_id, if ancestry.nil? then "#{node.id}" else "#{ancestry}/#{node.id}" end
    end
  end

  def update_units_fond_id
    case adapter
    when 'sqlite'
      ar_connection.execute("UPDATE units
                           SET fond_id = (SELECT fonds.id FROM fonds
                           WHERE units.legacy_parent_fond_id = fonds.legacy_id
                           AND units.db_source = '#{self.identifier}'
                           AND fonds.db_source = '#{self.identifier}')
                           WHERE EXISTS (
                            SELECT * FROM fonds
                            WHERE units.legacy_parent_fond_id = fonds.legacy_id
                            AND units.db_source = '#{self.identifier}'
                            AND fonds.db_source = '#{self.identifier}')")
      ar_connection.execute("UPDATE units
                           SET root_fond_id = (SELECT fonds.id FROM fonds
                           WHERE units.legacy_root_fond_id = fonds.legacy_id
                           AND units.db_source = '#{self.identifier}'
                           AND fonds.db_source = '#{self.identifier}')
                           WHERE EXISTS (
                            SELECT * FROM fonds
                            WHERE units.legacy_root_fond_id = fonds.legacy_id
                            AND units.db_source = '#{self.identifier}'
                            AND fonds.db_source = '#{self.identifier}')")
    when 'mysql', 'mysql2'
      ar_connection.execute("UPDATE units u, fonds f
                           SET u.fond_id = f.id
                           WHERE u.legacy_parent_fond_id = f.legacy_id
                           AND u.db_source = '#{self.identifier}'
                           AND f.db_source = '#{self.identifier}'")

      ar_connection.execute("UPDATE units u, fonds f
                           SET u.root_fond_id = f.id
                           WHERE u.legacy_root_fond_id = f.legacy_id
                           AND u.db_source = '#{self.identifier}'
                           AND f.db_source = '#{self.identifier}'")
    when 'postgresql'
      ar_connection.execute("UPDATE units
                           SET fond_id = f.id
                           FROM fonds f
                           WHERE units.legacy_parent_fond_id = f.legacy_id
                           AND units.db_source = '#{self.identifier}'
                           AND f.db_source = '#{self.identifier}'")

      ar_connection.execute("UPDATE units
                           SET root_fond_id = f.id
                           FROM fonds f
                           WHERE units.legacy_root_fond_id = f.legacy_id
                           AND units.db_source = '#{self.identifier}'
                           AND f.db_source = '#{self.identifier}'")
    end
  end

  def update_subunits_ancestry
    case adapter
    when 'sqlite'
      (1..2).each do |n|
        ancestry = n == 1 ? "id" : "ancestry || '/' || id"
        ar_connection.execute("UPDATE units
                              SET ancestry = (SELECT #{ancestry}
                              FROM units parents
                              WHERE units.db_source = '#{self.identifier}'
                              AND parents.db_source = '#{self.identifier}'
                              AND units.legacy_parent_unit_id = parents.legacy_id
                              AND units.ancestry_depth = #{n})
                              WHERE EXISTS (
                                SELECT * FROM units parents
                                WHERE units.db_source = '#{self.identifier}'
                                AND parents.db_source = '#{self.identifier}'
                                AND units.legacy_parent_unit_id = parents.legacy_id
                                AND units.ancestry_depth = #{n});")
      end
    when 'mysql', 'mysql2'
      (1..2).each do |n|
        ar_connection.execute("UPDATE units u, units parents
                              SET u.ancestry = CONCAT_WS('/', parents.ancestry, CAST(parents.id AS char))
                              WHERE u.db_source = '#{self.identifier}'
                              AND parents.db_source = '#{self.identifier}'
                              AND u.legacy_parent_unit_id = parents.legacy_id
                              AND u.ancestry_depth = #{n};")
      end
    when 'postgresql'
      (1..2).each do |n|
        ar_connection.execute("UPDATE units
                             SET ancestry = CONCAT_WS('/', parents.ancestry, CAST(parents.id AS varchar))
                             FROM units parents
                             WHERE units.db_source = '#{self.identifier}'
                             AND parents.db_source = '#{self.identifier}'
                             AND units.legacy_parent_unit_id = parents.legacy_id
                             AND units.ancestry_depth = #{n};")
      end
    end
  end

  def update_one_to_many_relations
    entities = {
      :fonds => ["fond_events", "fond_identifiers", "fond_langs", "fond_names", "fond_owners", "fond_urls", "fond_editors"],
      :units => ["unit_events", "unit_identifiers", "unit_damages", "unit_langs", "unit_other_reference_numbers", "unit_urls", "unit_editors","iccd_authors", "iccd_descriptions", "iccd_tech_specs", "iccd_damages", "iccd_subjects"],
      :creators => ["creator_events", "creator_identifiers", "creator_legal_statuses", "creator_names", "creator_urls", "creator_activities", "creator_editors"],
      :custodians => ["custodian_buildings", "custodian_contacts", "custodian_identifiers", "custodian_names", "custodian_owners", "custodian_urls", "custodian_editors"],
      :projects => ["project_credits", "project_urls"],
      :sources => ["source_urls"],
      :institutions => ["institution_editors"],
      :document_forms => ["document_form_editors"]
    }

    entities.each do |target, tables|
      target_field = "#{target}".singularize + "_id"
      tables.each do |table|
        case adapter
        when 'sqlite'
          ar_connection.execute("UPDATE #{table} SET #{target_field} = (SELECT id
                                 FROM #{target}
                                 WHERE #{table}.legacy_id = #{target}.legacy_id
                                 AND #{table}.db_source = #{target}.db_source
                                 AND #{target}.db_source = '#{self.identifier}')
                                 WHERE EXISTS (
                                  SELECT * FROM #{target}
                                  WHERE #{table}.legacy_id = #{target}.legacy_id
                                  AND #{table}.db_source = #{target}.db_source
                                  AND #{target}.db_source = '#{self.identifier}')")
        when 'mysql', 'mysql2'
          ar_connection.execute("UPDATE #{table} r, #{target} c SET r.#{target_field} = c.id
                                 WHERE r.legacy_id = c.legacy_id
                                 AND r.db_source = c.db_source
                                 AND c.db_source = '#{self.identifier}'")
        when 'postgresql'
          ar_connection.execute("UPDATE #{table} SET #{target_field} = c.id FROM #{target} c
                                 WHERE #{table}.legacy_id = c.legacy_id
                                 AND #{table}.db_source = c.db_source
                                 AND c.db_source = '#{self.identifier}'")
        end
      end
    end
  end

  def update_many_to_many_relations
    tables = {
      :rel_creator_creators => ["creators", "creators"],
      :rel_creator_fonds => ["creators", "fonds"],
      :rel_creator_institutions => ["creators", "institutions"],
      :rel_creator_sources => ["creators", "sources"],
      :rel_custodian_fonds => ["custodians", "fonds"],
      :rel_custodian_sources => ["custodians", "sources"],
      :rel_fond_document_forms => ["fonds", "document_forms"],
      :rel_fond_headings => ["fonds", "headings"],
      :rel_fond_sources => ["fonds", "sources"],
      :rel_project_fonds => ["projects", "fonds"],
      :rel_unit_headings => ["units", "headings"],
      :rel_unit_sources => ["units", "sources"]
    }

    tables.each do |table, entities|
      first_entity_field = "#{entities[0]}".singularize + "_id"
      first_legacy_entity_field = "legacy_" + "#{entities[0]}".singularize + "_id"

      if entities[0] == entities[1]
        second_entity_field = "related_" + "#{entities[1]}".singularize + "_id"
        second_legacy_entity_field = "legacy_related_" + "#{entities[1]}".singularize + "_id"
      else
        second_entity_field = "#{entities[1]}".singularize + "_id"
        second_legacy_entity_field = "legacy_" + "#{entities[1]}".singularize + "_id"
      end

      case adapter
      when 'sqlite'
        query = "UPDATE #{table}
                 SET #{first_entity_field} = (SELECT id
                 FROM #{entities[0]}
                 WHERE #{table}.#{first_legacy_entity_field} = #{entities[0]}.legacy_id
                 AND #{table}.db_source = '#{self.identifier}'
                 AND #{entities[0]}.db_source = '#{self.identifier}')
                 WHERE EXISTS (
                    SELECT * FROM #{entities[0]}
                    WHERE #{table}.#{first_legacy_entity_field} = #{entities[0]}.legacy_id
                    AND #{table}.db_source = '#{self.identifier}'
                    AND #{entities[0]}.db_source = '#{self.identifier}');"
        ar_connection.execute(query)
      when 'mysql', 'mysql2'
        query = "UPDATE #{table} r, #{entities[0]} c
                 SET r.#{first_entity_field} = c.id
                 WHERE r.#{first_legacy_entity_field} = c.legacy_id
                 AND r.db_source = '#{self.identifier}'
                 AND c.db_source = '#{self.identifier}'"
        ar_connection.execute(query)
      when 'postgresql'
        query = "UPDATE #{table}
                 SET #{first_entity_field} = c.id
                 FROM #{entities[0]} c
                 WHERE #{table}.#{first_legacy_entity_field} = c.legacy_id
                 AND #{table}.db_source = '#{self.identifier}'
                 AND c.db_source = '#{self.identifier}'"
        ar_connection.execute(query)
      end

      case adapter
      when 'sqlite'
        query = "UPDATE #{table}
                 SET #{second_entity_field} = (SELECT id
                 FROM #{entities[1]}
                 WHERE #{table}.#{second_legacy_entity_field} = #{entities[1]}.legacy_id
                 AND #{table}.db_source = '#{self.identifier}'
                 AND #{entities[1]}.db_source = '#{self.identifier}')
                 WHERE EXISTS (
                    SELECT * FROM #{entities[1]}
                    WHERE #{table}.#{second_legacy_entity_field} = #{entities[1]}.legacy_id
                    AND #{table}.db_source = '#{self.identifier}'
                    AND #{entities[1]}.db_source = '#{self.identifier}');"
        ar_connection.execute(query)
      when 'mysql', 'mysql2'
        query = "UPDATE #{table} r, #{entities[1]} c
                 SET r.#{second_entity_field} = c.id
                 WHERE r.#{second_legacy_entity_field} = c.legacy_id
                 AND r.db_source = '#{self.identifier}'
                 AND c.db_source = '#{self.identifier}'"
        ar_connection.execute(query)
      when 'postgresql'
        query = "UPDATE #{table}
                 SET #{second_entity_field} = c.id
                 FROM #{entities[1]} c
                 WHERE #{table}.#{second_legacy_entity_field} = c.legacy_id
                 AND #{table}.db_source = '#{self.identifier}'
                 AND c.db_source = '#{self.identifier}'"
        ar_connection.execute(query)
      end

    end
  end

  def update_digital_objects
    attachable_entities = {
      'Fond' => 'fonds',
      'Unit' => 'units',
      'Creator' => 'creators',
      'Custodian' => 'custodians',
      'Source' => 'sources'
    }

    attachable_entities.each do |value, table|
      set = DigitalObject.all(:conditions => {:attachable_type => value, :db_source => self.identifier})
      unless set.blank?
        ids = set.map(&:id).join(',')
        case adapter
        when 'sqlite'
          query = "UPDATE digital_objects SET attachable_id = (SELECT id
                   FROM #{table}
                   WHERE digital_objects.legacy_id = #{table}.legacy_id
                   AND digital_objects.db_source = #{table}.db_source
                   AND #{table}.db_source = '#{self.identifier}'
                   AND digital_objects.id IN (#{ids}))
                   WHERE EXISTS (
                    SELECT * FROM #{table}
                    WHERE digital_objects.legacy_id = #{table}.legacy_id
                    AND digital_objects.db_source = #{table}.db_source
                    AND #{table}.db_source = '#{self.identifier}'
                    AND digital_objects.id IN (#{ids}));"
          ar_connection.execute(query)
        when 'mysql', 'mysql2'
          query = "UPDATE digital_objects do, #{table} e SET do.attachable_id = e.id
                   WHERE do.legacy_id = e.legacy_id
                   AND do.db_source = e.db_source
                   AND e.db_source = '#{self.identifier}'
                   AND do.id IN (#{ids})"
          ar_connection.execute(query)
        when 'postgresql'
          query = "UPDATE digital_objects SET attachable_id = e.id
                   FROM #{table} e
                   WHERE digital_objects.legacy_id = e.legacy_id
                   AND digital_objects.db_source = e.db_source
                   AND e.db_source = '#{self.identifier}'
                   AND digital_objects.id IN (#{ids})"
          ar_connection.execute(query)
        end
      end
    end
  end

  def is_valid_file?
    begin
      extension = File.extname(data_file_name).downcase.gsub('.', '')
      raise Zip::ZipInternalError unless ['aef'].include? extension
    rescue Zip::ZipInternalError
      raise 'Il file fornito non è di formato <code>aef</code>'
    end

    files = ["metadata.json", "data.json"]

    begin
      Zip::ZipFile.open("#{Rails.root}/public/imports/#{self.id}/#{self.data_file_name}") do |zipfile|
        zipfile.each do |entry|
          raise Zip::ZipEntryNameError unless files.include? entry.to_s
          zipfile.extract(entry, TMP_IMPORTS + "/#{self.id}_#{entry.to_s}")
        end
      end
    rescue Zip::ZipInternalError
      raise 'Il file fornito non è di formato <code>aef</code>'
    rescue Zip::ZipEntryNameError
      raise 'Il file fornito contiene dati non validi'
    rescue Zip::ZipCompressionMethodError
      raise 'Il file <code>aef</code> è danneggiato'
    rescue Zip::ZipDestinationFileExistsError
      raise "Errore interno di #{APP_NAME}, <em>stale files</em> nella directory tmp"
    rescue
      raise "Si è verificato un errore nell'elaborazione del file <code>aef</code>"
    end

    File.open(metadata_file) do |file|
      begin
        lines = file.enum_for(:each_line)
        lines.each do |line|
          next if line.blank?
          data = ActiveSupport::JSON.decode(line.strip)
          raise "Controllo di integrità fallito" unless data['checksum'] == Digest::SHA256.file(data_file).hexdigest
          unless AEF_COMPATIBLE_VERSIONS.include?(data['version'])
            aef_version = data['version'].to_s.scan(%r([0-9])).join(".")
            raise "File incompatibile con questa versione di #{APP_NAME} (#{APP_VERSION}).<br>
            Il file <code>aef</code> è stato prodotto con la versione #{aef_version}."
          end
          self.importable_type = data['attached_entity']
        end
      rescue Exception => e
        raise e.message
      ensure
        file.close
      end
    end
  end

  def wipe_all_related_records
    tables = ar_connection.tables - ["schema_migrations"]
    begin
      ActiveRecord::Base.transaction do
        tables.each do |table|
          model = table.classify.constantize
          object = model.new
          if object.has_attribute? 'db_source'
            model.delete_all("db_source = '#{self.identifier}'")
          end
        end
      end
      return true
    rescue
      return false
    end
  end

  private

  def sanitize_file_name
    extension = File.extname(data_file_name).downcase
    filename = "#{Time.now.strftime("%Y%m%d%H%M%S")}"
    self.data.instance_write(:file_name, "#{filename}#{extension}")
  end
end
