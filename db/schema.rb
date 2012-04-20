# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20120419122402) do

  create_table "activities", :force => true do |t|
    t.string   "identifier"
    t.string   "identifier_source"
    t.string   "activity_en"
    t.string   "activity_it"
    t.integer  "parent_id"
    t.string   "native",            :limit => 1
    t.string   "grouping",          :limit => 1
    t.string   "db_source"
    t.string   "legacy_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "activities", ["db_source", "legacy_id"], :name => "index_activities_on_source_and_legacy_id"

  create_table "creator_activities", :force => true do |t|
    t.integer  "creator_id"
    t.string   "activity"
    t.string   "note"
    t.string   "db_source"
    t.string   "legacy_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "creator_activities", ["creator_id"], :name => "index_creator_activities_on_creator_id"
  add_index "creator_activities", ["db_source", "legacy_id"], :name => "index_creator_activities_on_source_and_legacy_id"

  create_table "creator_association_types", :force => true do |t|
    t.integer  "inverse_type_id"
    t.string   "association_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "creator_corporate_types", :force => true do |t|
    t.string   "corporate_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "creator_editors", :force => true do |t|
    t.integer  "creator_id"
    t.string   "name"
    t.string   "qualifier"
    t.string   "editing_type"
    t.date     "edited_at"
    t.string   "db_source"
    t.integer  "legacy_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "creator_editors", ["creator_id"], :name => "index_creator_editors_on_creator_id"
  add_index "creator_editors", ["db_source", "legacy_id"], :name => "index_creator_editors_on_source_and_legacy_id"

  create_table "creator_events", :force => true do |t|
    t.integer  "creator_id",                             :null => false
    t.boolean  "preferred",           :default => false
    t.boolean  "is_valid",            :default => true,  :null => false
    t.string   "start_date_place"
    t.string   "start_date_spec"
    t.date     "start_date_from"
    t.date     "start_date_to"
    t.string   "start_date_valid"
    t.string   "start_date_format"
    t.string   "start_date_display"
    t.string   "end_date_place"
    t.string   "end_date_spec"
    t.date     "end_date_from"
    t.date     "end_date_to"
    t.string   "end_date_valid"
    t.string   "end_date_format"
    t.string   "end_date_display"
    t.string   "legacy_display_date"
    t.string   "order_date"
    t.text     "note"
    t.string   "db_source"
    t.string   "legacy_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "creator_events", ["creator_id"], :name => "index_creator_events_on_creator_id"
  add_index "creator_events", ["db_source", "legacy_id"], :name => "index_creator_events_on_source_and_legacy_id"

  create_table "creator_identifiers", :force => true do |t|
    t.integer  "creator_id"
    t.string   "identifier"
    t.string   "identifier_source"
    t.text     "note"
    t.string   "db_source"
    t.string   "legacy_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "creator_identifiers", ["creator_id"], :name => "index_creator_identifiers_on_creator_id"
  add_index "creator_identifiers", ["db_source", "legacy_id"], :name => "index_creator_identifiers_on_source_and_legacy_id"

  create_table "creator_legal_statuses", :force => true do |t|
    t.integer  "creator_id"
    t.string   "legal_status"
    t.text     "note"
    t.string   "db_source"
    t.string   "legacy_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "creator_legal_statuses", ["creator_id"], :name => "index_creator_legal_statuses_on_creator_id"
  add_index "creator_legal_statuses", ["db_source", "legacy_id"], :name => "index_creator_legal_statuses_on_source_and_legacy_id"

  create_table "creator_names", :force => true do |t|
    t.integer  "creator_id"
    t.boolean  "preferred",  :default => false
    t.string   "name"
    t.string   "first_name"
    t.string   "last_name"
    t.text     "note"
    t.string   "qualifier"
    t.string   "patronymic"
    t.string   "nickname"
    t.string   "db_source"
    t.string   "legacy_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "creator_names", ["creator_id"], :name => "index_creator_names_on_creator_id"
  add_index "creator_names", ["db_source", "legacy_id"], :name => "index_creator_names_on_source_and_legacy_id"

  create_table "creator_urls", :force => true do |t|
    t.integer  "creator_id"
    t.string   "url"
    t.text     "note"
    t.integer  "position"
    t.string   "db_source"
    t.string   "legacy_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "creator_urls", ["creator_id"], :name => "index_creator_urls_on_creator_id"
  add_index "creator_urls", ["db_source", "legacy_id"], :name => "index_creator_urls_on_source_and_legacy_id"

  create_table "creators", :force => true do |t|
    t.string   "creator_type",              :limit => 1
    t.integer  "creator_corporate_type_id"
    t.string   "residence"
    t.text     "abstract"
    t.text     "history"
    t.string   "legal_status"
    t.text     "note"
    t.integer  "created_by",                             :default => 1
    t.integer  "updated_by",                             :default => 1
    t.integer  "group_id",                               :default => 1
    t.string   "db_source"
    t.string   "legacy_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "creators", ["creator_corporate_type_id"], :name => "index_creators_on_creator_corporate_type_id"
  add_index "creators", ["creator_type"], :name => "index_creators_on_creator_type"
  add_index "creators", ["db_source", "legacy_id"], :name => "index_creators_on_source_and_legacy_id"
  add_index "creators", ["group_id"], :name => "index_creators_on_group_id"

  create_table "custodian_buildings", :force => true do |t|
    t.integer  "custodian_id"
    t.string   "custodian_building_type"
    t.string   "name"
    t.text     "description"
    t.string   "address"
    t.string   "postcode"
    t.string   "city"
    t.string   "state"
    t.string   "country"
    t.string   "db_source"
    t.string   "legacy_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "custodian_buildings", ["custodian_id"], :name => "index_custodian_buildings_on_custodian_id"
  add_index "custodian_buildings", ["db_source", "legacy_id"], :name => "index_custodian_buildings_on_source_and_legacy_id"

  create_table "custodian_contacts", :force => true do |t|
    t.integer  "custodian_id"
    t.string   "contact"
    t.string   "contact_type"
    t.string   "contact_note"
    t.string   "db_source"
    t.string   "legacy_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "custodian_contacts", ["custodian_id"], :name => "index_custodian_contacts_on_custodian_id"
  add_index "custodian_contacts", ["db_source", "legacy_id"], :name => "index_custodian_contacts_on_source_and_legacy_id"

  create_table "custodian_editors", :force => true do |t|
    t.integer  "custodian_id"
    t.string   "name"
    t.string   "qualifier"
    t.string   "editing_type"
    t.date     "edited_at"
    t.string   "db_source"
    t.integer  "legacy_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "custodian_editors", ["custodian_id"], :name => "index_custodian_editors_on_custodian_id"
  add_index "custodian_editors", ["db_source", "legacy_id"], :name => "index_custodian_editors_on_source_and_legacy_id"

  create_table "custodian_identifiers", :force => true do |t|
    t.integer  "custodian_id"
    t.string   "identifier"
    t.string   "identifier_source"
    t.text     "note"
    t.string   "db_source"
    t.string   "legacy_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "custodian_identifiers", ["custodian_id"], :name => "index_custodian_identifiers_on_custodian_id"
  add_index "custodian_identifiers", ["db_source", "legacy_id"], :name => "index_custodian_identifiers_on_source_and_legacy_id"

  create_table "custodian_names", :force => true do |t|
    t.integer  "custodian_id"
    t.boolean  "preferred",    :default => false
    t.string   "name"
    t.string   "qualifier"
    t.text     "note"
    t.string   "db_source"
    t.string   "legacy_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "custodian_names", ["custodian_id"], :name => "index_custodian_names_on_custodian_id"
  add_index "custodian_names", ["db_source", "legacy_id"], :name => "index_custodian_names_on_source_and_legacy_id"

  create_table "custodian_owners", :force => true do |t|
    t.integer  "custodian_id"
    t.string   "owner"
    t.string   "db_source"
    t.string   "legacy_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "custodian_owners", ["custodian_id"], :name => "index_custodian_owners_on_custodian_id"
  add_index "custodian_owners", ["db_source", "legacy_id"], :name => "index_custodian_owners_on_source_and_legacy_id"

  create_table "custodian_types", :force => true do |t|
    t.string   "custodian_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "custodian_urls", :force => true do |t|
    t.integer  "custodian_id"
    t.string   "url"
    t.text     "note"
    t.integer  "position"
    t.string   "db_source"
    t.string   "legacy_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "custodian_urls", ["custodian_id"], :name => "index_custodian_urls_on_custodian_id"
  add_index "custodian_urls", ["db_source", "legacy_id"], :name => "index_custodian_urls_on_source_and_legacy_id"

  create_table "custodians", :force => true do |t|
    t.integer  "custodian_type_id"
    t.string   "legal_status",             :limit => 2
    t.string   "owner"
    t.string   "contact_person"
    t.text     "history"
    t.text     "administrative_structure"
    t.text     "collecting_policies"
    t.text     "holdings"
    t.text     "accessibility"
    t.text     "services"
    t.integer  "created_by",                            :default => 1
    t.integer  "updated_by",                            :default => 1
    t.integer  "group_id",                              :default => 1
    t.string   "db_source"
    t.string   "legacy_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "custodians", ["custodian_type_id"], :name => "index_custodians_on_custodian_type_id"
  add_index "custodians", ["db_source", "legacy_id"], :name => "index_custodians_on_source_and_legacy_id"
  add_index "custodians", ["group_id"], :name => "index_custodians_on_group_id"

  create_table "digital_objects", :force => true do |t|
    t.string   "attachable_type"
    t.integer  "attachable_id"
    t.integer  "position"
    t.string   "title"
    t.text     "description"
    t.string   "access_token"
    t.string   "asset_file_name"
    t.string   "asset_content_type"
    t.integer  "asset_file_size"
    t.datetime "asset_updated_at"
    t.integer  "created_by"
    t.integer  "updated_by"
    t.integer  "group_id"
    t.string   "db_source"
    t.string   "legacy_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "digital_objects", ["attachable_type", "attachable_id"], :name => "index_digital_objects_on_attachable_type_and_attachable_id"
  add_index "digital_objects", ["db_source", "legacy_id"], :name => "index_digital_objects_on_source_and_legacy_id"

  create_table "document_form_editors", :force => true do |t|
    t.integer  "document_form_id"
    t.string   "name"
    t.string   "qualifier"
    t.string   "editing_type"
    t.date     "edited_at"
    t.string   "db_source"
    t.integer  "legacy_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "document_form_editors", ["db_source", "legacy_id"], :name => "index_document_form_editors_on_source_and_legacy_id"
  add_index "document_form_editors", ["document_form_id"], :name => "index_document_form_editors_on_document_form_id"

  create_table "document_forms", :force => true do |t|
    t.string   "identifier_source"
    t.string   "identifier"
    t.string   "name"
    t.text     "description"
    t.integer  "status"
    t.text     "note"
    t.integer  "created_by"
    t.integer  "updated_by"
    t.integer  "group_id"
    t.string   "db_source"
    t.string   "legacy_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "document_forms", ["db_source", "legacy_id"], :name => "index_document_forms_on_source_and_legacy_id"

  create_table "editors", :force => true do |t|
    t.string   "first_name"
    t.string   "last_name"
    t.integer  "created_by"
    t.integer  "updated_by"
    t.integer  "group_id"
    t.string   "db_source"
    t.string   "legacy_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "editors", ["db_source", "legacy_id"], :name => "index_editors_on_source_and_legacy_id"
  add_index "editors", ["group_id"], :name => "index_editors_on_group_id"

  create_table "fond_editors", :force => true do |t|
    t.integer  "fond_id"
    t.string   "name"
    t.string   "qualifier"
    t.string   "editing_type"
    t.date     "edited_at"
    t.string   "db_source"
    t.integer  "legacy_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "fond_editors", ["db_source", "legacy_id"], :name => "index_fond_editors_on_source_and_legacy_id"
  add_index "fond_editors", ["fond_id"], :name => "index_fond_editors_on_fond_id"

  create_table "fond_events", :force => true do |t|
    t.integer  "fond_id",                                :null => false
    t.boolean  "preferred",           :default => false
    t.boolean  "is_valid",            :default => true,  :null => false
    t.string   "start_date_place"
    t.string   "start_date_spec"
    t.date     "start_date_from"
    t.date     "start_date_to"
    t.string   "start_date_valid"
    t.string   "start_date_format"
    t.string   "start_date_display"
    t.string   "end_date_place"
    t.string   "end_date_spec"
    t.date     "end_date_from"
    t.date     "end_date_to"
    t.string   "end_date_valid"
    t.string   "end_date_format"
    t.string   "end_date_display"
    t.string   "legacy_display_date"
    t.string   "order_date"
    t.text     "note"
    t.string   "db_source"
    t.string   "legacy_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "fond_events", ["db_source", "legacy_id"], :name => "index_fond_events_on_source_and_legacy_id"
  add_index "fond_events", ["fond_id"], :name => "index_fond_events_on_fond_id"

  create_table "fond_identifiers", :force => true do |t|
    t.integer  "fond_id"
    t.string   "identifier"
    t.string   "identifier_source"
    t.text     "note"
    t.string   "db_source"
    t.string   "legacy_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "fond_identifiers", ["db_source", "legacy_id"], :name => "index_fond_identifiers_on_source_and_legacy_id"
  add_index "fond_identifiers", ["fond_id"], :name => "index_fond_identifiers_on_fond_id"

  create_table "fond_langs", :force => true do |t|
    t.integer  "fond_id"
    t.string   "code",       :limit => 3
    t.string   "db_source"
    t.string   "legacy_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "fond_langs", ["db_source", "legacy_id"], :name => "index_fond_langs_on_source_and_legacy_id"
  add_index "fond_langs", ["fond_id"], :name => "index_fond_langs_on_fond_id"

  create_table "fond_names", :force => true do |t|
    t.integer  "fond_id"
    t.string   "name"
    t.string   "qualifier"
    t.text     "note"
    t.string   "db_source"
    t.string   "legacy_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "fond_names", ["db_source", "legacy_id"], :name => "index_fond_names_on_source_and_legacy_id"
  add_index "fond_names", ["fond_id"], :name => "index_fond_names_on_fond_id"

  create_table "fond_owners", :force => true do |t|
    t.integer  "fond_id"
    t.string   "owner"
    t.string   "db_source"
    t.string   "legacy_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "fond_owners", ["db_source", "legacy_id"], :name => "index_fond_owners_on_source_and_legacy_id"
  add_index "fond_owners", ["fond_id"], :name => "index_fond_owners_on_fond_id"

  create_table "fond_urls", :force => true do |t|
    t.integer  "fond_id"
    t.string   "url"
    t.text     "note"
    t.integer  "position"
    t.string   "db_source"
    t.string   "legacy_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "fond_urls", ["db_source", "legacy_id"], :name => "index_fond_urls_on_source_and_legacy_id"
  add_index "fond_urls", ["fond_id"], :name => "index_fond_urls_on_fond_id"

  create_table "fonds", :force => true do |t|
    t.string   "ancestry"
    t.integer  "ancestry_depth"
    t.integer  "position",              :default => 0
    t.integer  "sequence_number"
    t.boolean  "trashed",               :default => false, :null => false
    t.integer  "trashed_ancestor_id"
    t.integer  "units_count",           :default => 0,     :null => false
    t.string   "name"
    t.string   "fond_type"
    t.float    "length"
    t.text     "extent"
    t.text     "abstract"
    t.text     "description"
    t.text     "history"
    t.text     "arrangement_note"
    t.text     "related_materials"
    t.string   "access_condition"
    t.text     "access_condition_note"
    t.string   "use_condition"
    t.text     "use_condition_note"
    t.string   "type_materials"
    t.string   "preservation"
    t.text     "preservation_note"
    t.string   "description_type"
    t.text     "note"
    t.integer  "created_by",            :default => 1
    t.integer  "updated_by",            :default => 1
    t.integer  "group_id",              :default => 1
    t.string   "db_source"
    t.string   "legacy_id"
    t.string   "legacy_parent_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "fonds", ["ancestry"], :name => "index_fonds_on_ancestry"
  add_index "fonds", ["db_source", "legacy_id"], :name => "index_fonds_on_source_and_legacy_id"
  add_index "fonds", ["db_source", "legacy_parent_id"], :name => "index_fonds_on_source_and_legacy_parent_id"
  add_index "fonds", ["group_id"], :name => "index_fonds_on_group_id"

  create_table "groups", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "headings", :force => true do |t|
    t.string   "heading_type"
    t.string   "name"
    t.string   "dates"
    t.string   "qualifier"
    t.integer  "group_id"
    t.string   "db_source"
    t.string   "legacy_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "headings", ["db_source", "legacy_id"], :name => "index_headings_on_source_and_legacy_id"

  create_table "iccd_authors", :force => true do |t|
    t.integer  "unit_id"
    t.string   "autn"
    t.string   "autm"
    t.string   "autk"
    t.string   "db_source"
    t.string   "legacy_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "iccd_authors", ["unit_id"], :name => "index_iccd_authors_on_unit_id"

  create_table "iccd_damages", :force => true do |t|
    t.integer  "unit_id"
    t.string   "stcs"
    t.string   "db_source"
    t.string   "legacy_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "iccd_descriptions", :force => true do |t|
    t.integer  "unit_id"
    t.string   "ogtd"
    t.string   "ogts"
    t.text     "sgtd"
    t.string   "utf"
    t.string   "uto"
    t.string   "esc"
    t.string   "pvc"
    t.string   "ldcn"
    t.string   "ldcu"
    t.string   "ldcm"
    t.string   "db_source"
    t.string   "legacy_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "iccd_descriptions", ["db_source", "legacy_id"], :name => "index_iccd_descriptions_on_db_source_and_legacy_id"
  add_index "iccd_descriptions", ["unit_id"], :name => "index_iccd_descriptions_on_unit_id"

  create_table "iccd_subjects", :force => true do |t|
    t.integer  "unit_id"
    t.string   "sgti"
    t.string   "db_source"
    t.string   "legacy_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "iccd_subjects", ["db_source", "legacy_id"], :name => "index_iccd_subjects_on_db_source_and_legacy_id"
  add_index "iccd_subjects", ["unit_id"], :name => "index_iccd_subjects_on_unit_id"

  create_table "iccd_tech_specs", :force => true do |t|
    t.integer  "unit_id"
    t.string   "mtx"
    t.string   "mtc"
    t.string   "misu"
    t.float    "misa"
    t.float    "misl"
    t.string   "miss"
    t.string   "mtct"
    t.string   "mtcm"
    t.string   "db_source"
    t.string   "legacy_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "iccd_tech_specs", ["db_source", "legacy_id"], :name => "index_iccd_tech_specs_on_db_source_and_legacy_id"
  add_index "iccd_tech_specs", ["unit_id"], :name => "index_iccd_tech_specs_on_unit_id"

  create_table "iccd_terms", :force => true do |t|
    t.integer  "iccd_vocabulary_id"
    t.integer  "position"
    t.string   "term_key"
    t.string   "term_value"
    t.string   "term_scope"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "iccd_terms_bdm_mtcms", :force => true do |t|
    t.string   "mtcm"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "iccd_terms_bdm_mtcts", :force => true do |t|
    t.string   "mtct"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "iccd_terms_bdm_ogtds", :force => true do |t|
    t.string   "ogtd"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "iccd_terms_oa_mtcs", :force => true do |t|
    t.string   "mtc"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "iccd_terms_oa_ogtds", :force => true do |t|
    t.string   "ogtd"
    t.string   "ogtt"
    t.string   "descr_ogtd"
    t.string   "descr_ogtt"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "iccd_vocabularies", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "iccd_vocabularies", ["name"], :name => "index_iccd_vocabularies_on_name"

  create_table "imports", :force => true do |t|
    t.integer  "user_id"
    t.string   "identifier"
    t.string   "data_file_name"
    t.integer  "group_id"
    t.boolean  "deletable",      :default => true
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "institution_editors", :force => true do |t|
    t.integer  "institution_id"
    t.string   "name"
    t.string   "qualifier"
    t.string   "editing_type"
    t.date     "edited_at"
    t.string   "db_source"
    t.integer  "legacy_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "institution_editors", ["db_source", "legacy_id"], :name => "index_institution_editors_on_source_and_legacy_id"
  add_index "institution_editors", ["institution_id"], :name => "index_institution_editors_on_institution_id"

  create_table "institutions", :force => true do |t|
    t.string   "identifier"
    t.string   "identifier_source"
    t.string   "name"
    t.text     "description"
    t.integer  "status"
    t.text     "note"
    t.integer  "created_by"
    t.integer  "updated_by"
    t.integer  "group_id"
    t.string   "db_source"
    t.string   "legacy_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "institutions", ["db_source", "legacy_id"], :name => "index_institutions_on_source_and_legacy_id"

  create_table "langs", :force => true do |t|
    t.string   "code",       :limit => 3
    t.string   "code3t",     :limit => 3
    t.string   "code2",      :limit => 2
    t.string   "en_name"
    t.string   "fr_name"
    t.string   "it_name"
    t.boolean  "active"
    t.integer  "position"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "places", :force => true do |t|
    t.string  "record_type",     :limit => 2
    t.string  "name",            :limit => 200
    t.string  "qualifier",       :limit => 100
    t.text    "ancestry_string"
    t.string  "ancestry"
    t.integer "ancestry_depth"
    t.string  "display_name"
  end

  create_table "project_credits", :force => true do |t|
    t.integer  "project_id"
    t.string   "credit_type"
    t.string   "qualifier"
    t.string   "credit_name"
    t.string   "db_source"
    t.string   "legacy_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "project_credits", ["db_source", "legacy_id"], :name => "index_project_credits_on_source_and_legacy_id"
  add_index "project_credits", ["project_id"], :name => "index_project_credits_on_project_id"

  create_table "project_urls", :force => true do |t|
    t.integer  "project_id"
    t.string   "url"
    t.text     "note"
    t.integer  "position"
    t.string   "db_source"
    t.string   "legacy_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "project_urls", ["db_source", "legacy_id"], :name => "index_project_urls_on_source_and_legacy_id"
  add_index "project_urls", ["project_id"], :name => "index_project_urls_on_project_id"

  create_table "projects", :force => true do |t|
    t.string   "project_type"
    t.string   "name"
    t.integer  "start_year"
    t.integer  "end_year"
    t.string   "status"
    t.text     "description"
    t.text     "note"
    t.integer  "created_by",   :default => 1
    t.integer  "updated_by",   :default => 1
    t.integer  "group_id",     :default => 1
    t.string   "db_source"
    t.string   "legacy_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "projects", ["db_source", "legacy_id"], :name => "index_projects_on_source_and_legacy_id"
  add_index "projects", ["group_id"], :name => "index_projects_on_group_id"

  create_table "rel_creator_creators", :force => true do |t|
    t.integer  "creator_id"
    t.integer  "related_creator_id"
    t.integer  "creator_association_type_id", :default => 1
    t.string   "legacy_qualifier"
    t.string   "db_source"
    t.string   "legacy_creator_id"
    t.string   "legacy_related_creator_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "rel_creator_creators", ["creator_id"], :name => "index_rel_creator_creators_on_creator_id"
  add_index "rel_creator_creators", ["db_source", "legacy_creator_id"], :name => "index_rel_creator_creators_on_source_and_legacy_creator_id"
  add_index "rel_creator_creators", ["related_creator_id"], :name => "index_rel_creator_creators_on_related_creator_id"

  create_table "rel_creator_fonds", :force => true do |t|
    t.integer  "creator_id"
    t.integer  "fond_id"
    t.string   "db_source"
    t.string   "legacy_creator_id"
    t.string   "legacy_fond_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "rel_creator_fonds", ["creator_id"], :name => "index_rel_creator_fonds_on_creator_id"
  add_index "rel_creator_fonds", ["db_source", "legacy_creator_id"], :name => "index_rel_creator_fonds_on_source_and_legacy_creator_id"
  add_index "rel_creator_fonds", ["db_source", "legacy_fond_id"], :name => "index_rel_creator_fonds_on_source_and_legacy_fond_id"
  add_index "rel_creator_fonds", ["fond_id"], :name => "index_rel_creator_fonds_on_fond_id"

  create_table "rel_creator_institutions", :force => true do |t|
    t.integer  "creator_id"
    t.integer  "institution_id"
    t.string   "db_source"
    t.string   "legacy_creator_id"
    t.string   "legacy_institution_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "rel_creator_institutions", ["creator_id"], :name => "index_rel_creator_institutions_on_creator_id"
  add_index "rel_creator_institutions", ["db_source", "legacy_creator_id"], :name => "index_rel_creator_institutions_on_source_and_legacy_creator_id"
  add_index "rel_creator_institutions", ["institution_id"], :name => "index_rel_creator_institutions_on_institution_id"

  create_table "rel_creator_sources", :force => true do |t|
    t.integer  "creator_id"
    t.integer  "source_id"
    t.string   "pages"
    t.string   "db_source"
    t.string   "legacy_creator_id"
    t.string   "legacy_source_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "rel_creator_sources", ["creator_id"], :name => "index_rel_creator_sources_on_creator_id"
  add_index "rel_creator_sources", ["db_source", "legacy_creator_id"], :name => "index_rel_creator_sources_on_source_and_legacy_creator_id"
  add_index "rel_creator_sources", ["db_source", "legacy_source_id"], :name => "index_rel_creator_sources_on_source_and_legacy_source_id"
  add_index "rel_creator_sources", ["source_id"], :name => "index_rel_creator_sources_on_source_id"

  create_table "rel_custodian_fonds", :force => true do |t|
    t.integer  "custodian_id"
    t.integer  "fond_id"
    t.string   "db_source"
    t.string   "legacy_custodian_id"
    t.string   "legacy_fond_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "rel_custodian_fonds", ["custodian_id"], :name => "index_rel_custodian_fonds_on_custodian_id"
  add_index "rel_custodian_fonds", ["db_source", "legacy_custodian_id"], :name => "index_rel_custodian_fonds_on_source_and_legacy_custodian_id"
  add_index "rel_custodian_fonds", ["db_source", "legacy_fond_id"], :name => "index_rel_custodian_fonds_on_source_and_legacy_fond_id"
  add_index "rel_custodian_fonds", ["fond_id"], :name => "index_rel_custodian_fonds_on_fond_id"

  create_table "rel_custodian_sources", :force => true do |t|
    t.integer  "custodian_id"
    t.integer  "source_id"
    t.string   "pages"
    t.string   "db_source"
    t.string   "legacy_custodian_id"
    t.string   "legacy_source_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "rel_custodian_sources", ["custodian_id"], :name => "index_rel_custodian_sources_on_custodian_id"
  add_index "rel_custodian_sources", ["db_source", "legacy_custodian_id"], :name => "index_rel_custodian_sources_on_source_and_legacy_custodian_id"
  add_index "rel_custodian_sources", ["db_source", "legacy_source_id"], :name => "index_rel_custodian_sources_on_source_and_legacy_source_id"
  add_index "rel_custodian_sources", ["source_id"], :name => "index_rel_custodian_sources_on_source_id"

  create_table "rel_fond_document_forms", :force => true do |t|
    t.integer  "fond_id"
    t.integer  "document_form_id"
    t.string   "db_source"
    t.string   "legacy_fond_id"
    t.string   "legacy_document_form_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "rel_fond_document_forms", ["db_source", "legacy_fond_id"], :name => "index_rel_fond_document_forms_on_source_and_legacy_fond_id"
  add_index "rel_fond_document_forms", ["document_form_id"], :name => "index_rel_fond_document_forms_on_document_form_id"
  add_index "rel_fond_document_forms", ["fond_id"], :name => "index_rel_fond_document_forms_on_fond_id"

  create_table "rel_fond_headings", :force => true do |t|
    t.integer  "fond_id"
    t.integer  "heading_id"
    t.string   "db_source"
    t.string   "legacy_fond_id"
    t.string   "legacy_heading_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "rel_fond_headings", ["db_source", "legacy_fond_id"], :name => "index_rel_fond_headings_on_source_and_legacy_fond_id"
  add_index "rel_fond_headings", ["db_source", "legacy_heading_id"], :name => "index_rel_fond_headings_on_source_and_legacy_heading_id"
  add_index "rel_fond_headings", ["fond_id"], :name => "index_rel_fond_headings_on_fond_id"
  add_index "rel_fond_headings", ["heading_id"], :name => "index_rel_fond_headings_on_heading_id"

  create_table "rel_fond_sources", :force => true do |t|
    t.integer  "fond_id"
    t.integer  "source_id"
    t.string   "pages"
    t.string   "db_source"
    t.string   "legacy_fond_id"
    t.string   "legacy_source_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "rel_fond_sources", ["db_source", "legacy_fond_id"], :name => "index_rel_fond_sources_on_source_and_legacy_fond_id"
  add_index "rel_fond_sources", ["db_source", "legacy_source_id"], :name => "index_rel_fond_sources_on_source_and_legacy_source_id"
  add_index "rel_fond_sources", ["fond_id"], :name => "index_rel_fond_sources_on_fond_id"
  add_index "rel_fond_sources", ["source_id"], :name => "index_rel_fond_sources_on_source_id"

  create_table "rel_project_fonds", :force => true do |t|
    t.integer  "project_id"
    t.integer  "fond_id"
    t.string   "db_source"
    t.string   "legacy_project_id"
    t.string   "legacy_fond_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "rel_project_fonds", ["db_source", "legacy_fond_id"], :name => "index_rel_project_fonds_on_source_and_legacy_fond_id"
  add_index "rel_project_fonds", ["db_source", "legacy_project_id"], :name => "index_rel_project_fonds_on_source_and_legacy_project_id"
  add_index "rel_project_fonds", ["fond_id"], :name => "index_rel_project_fonds_on_fond_id"
  add_index "rel_project_fonds", ["project_id"], :name => "index_rel_project_fonds_on_project_id"

  create_table "rel_unit_headings", :force => true do |t|
    t.integer  "unit_id"
    t.integer  "heading_id"
    t.string   "db_source"
    t.string   "legacy_unit_id"
    t.string   "legacy_heading_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "rel_unit_headings", ["db_source", "legacy_heading_id"], :name => "index_rel_unit_headings_on_source_and_legacy_heading_id"
  add_index "rel_unit_headings", ["db_source", "legacy_unit_id"], :name => "index_rel_unit_headings_on_source_and_legacy_unit_id"
  add_index "rel_unit_headings", ["heading_id"], :name => "index_rel_unit_headings_on_heading_id"
  add_index "rel_unit_headings", ["unit_id"], :name => "index_rel_unit_headings_on_unit_id"

  create_table "rel_unit_sources", :force => true do |t|
    t.integer  "unit_id"
    t.integer  "source_id"
    t.string   "pages"
    t.string   "db_source"
    t.string   "legacy_unit_id"
    t.string   "legacy_source_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "rel_unit_sources", ["db_source", "legacy_source_id"], :name => "index_rel_unit_sources_on_source_and_legacy_source_id"
  add_index "rel_unit_sources", ["db_source", "legacy_unit_id"], :name => "index_rel_unit_sources_on_source_and_legacy_unit_id"
  add_index "rel_unit_sources", ["source_id"], :name => "index_rel_unit_sources_on_source_id"
  add_index "rel_unit_sources", ["unit_id"], :name => "index_rel_unit_sources_on_unit_id"

  create_table "source_types", :force => true do |t|
    t.integer  "code"
    t.string   "source_type"
    t.integer  "parent_code"
    t.integer  "position"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "source_urls", :force => true do |t|
    t.integer  "source_id"
    t.string   "url"
    t.text     "note"
    t.integer  "position"
    t.string   "db_source"
    t.string   "legacy_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "source_urls", ["db_source", "legacy_id"], :name => "index_source_urls_on_source_and_legacy_id"
  add_index "source_urls", ["source_id"], :name => "index_source_urls_on_source_id"

  create_table "sources", :force => true do |t|
    t.boolean  "use_legacy",            :default => false
    t.integer  "source_type_code"
    t.integer  "source_subtype_code"
    t.string   "short_title"
    t.string   "author"
    t.text     "title"
    t.string   "editor"
    t.string   "publisher"
    t.string   "place"
    t.integer  "year",                  :default => 0
    t.string   "date_string"
    t.string   "related_item"
    t.string   "related_item_specs"
    t.text     "abstract"
    t.string   "identifier"
    t.boolean  "finding_aid_published"
    t.boolean  "finding_aid_valid"
    t.integer  "created_by"
    t.integer  "updated_by"
    t.integer  "group_id"
    t.string   "db_source"
    t.string   "legacy_id"
    t.string   "legacy_table"
    t.text     "legacy_description"
    t.text     "legacy_authors"
    t.string   "x_periodical"
    t.string   "x_issue"
    t.string   "x_volume"
    t.string   "x_pages"
    t.string   "x_book_title"
    t.string   "x_institution"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sources", ["db_source", "legacy_id"], :name => "index_sources_on_source_and_legacy_id"
  add_index "sources", ["source_subtype_code"], :name => "index_sources_on_source_subtype_code"
  add_index "sources", ["source_type_code"], :name => "index_sources_on_source_type_code"

  create_table "terms", :force => true do |t|
    t.integer  "vocabulary_id"
    t.integer  "position"
    t.string   "term_key"
    t.string   "term_value"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "terms", ["vocabulary_id"], :name => "index_terms_on_vocabulary_id"

  create_table "tmp_ordered_nodes", :id => false, :force => true do |t|
    t.integer "node_id"
    t.integer "rank"
  end

  add_index "tmp_ordered_nodes", ["node_id"], :name => "index_tmp_ordered_nodes_on_node_id"

  create_table "unit_damages", :force => true do |t|
    t.integer  "unit_id"
    t.string   "code"
    t.string   "note"
    t.string   "db_source"
    t.string   "legacy_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "unit_damages", ["db_source", "legacy_id"], :name => "index_unit_damages_on_source_and_legacy_id"
  add_index "unit_damages", ["unit_id"], :name => "index_unit_damages_on_unit_id"

  create_table "unit_editors", :force => true do |t|
    t.integer  "unit_id"
    t.string   "name"
    t.string   "qualifier"
    t.string   "editing_type"
    t.date     "edited_at"
    t.string   "db_source"
    t.integer  "legacy_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "unit_editors", ["db_source", "legacy_id"], :name => "index_unit_editors_on_source_and_legacy_id"
  add_index "unit_editors", ["unit_id"], :name => "index_unit_editors_on_unit_id"

  create_table "unit_events", :force => true do |t|
    t.integer  "unit_id",                                :null => false
    t.boolean  "preferred",           :default => false
    t.boolean  "is_valid",            :default => true,  :null => false
    t.string   "start_date_place"
    t.string   "start_date_spec"
    t.date     "start_date_from"
    t.date     "start_date_to"
    t.string   "start_date_valid"
    t.string   "start_date_format"
    t.string   "start_date_display"
    t.string   "end_date_place"
    t.string   "end_date_spec"
    t.date     "end_date_from"
    t.date     "end_date_to"
    t.string   "end_date_valid"
    t.string   "end_date_format"
    t.string   "end_date_display"
    t.string   "legacy_display_date"
    t.string   "order_date"
    t.text     "note"
    t.string   "db_source"
    t.string   "legacy_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "unit_events", ["db_source", "legacy_id"], :name => "index_unit_events_on_source_and_legacy_id"
  add_index "unit_events", ["unit_id"], :name => "index_unit_events_on_unit_id"

  create_table "unit_identifiers", :force => true do |t|
    t.integer  "unit_id"
    t.string   "identifier"
    t.string   "identifier_source"
    t.text     "note"
    t.string   "db_source"
    t.string   "legacy_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "unit_identifiers", ["db_source", "legacy_id"], :name => "index_unit_identifiers_on_source_and_legacy_id"
  add_index "unit_identifiers", ["unit_id"], :name => "index_unit_identifiers_on_unit_id"

  create_table "unit_langs", :force => true do |t|
    t.integer  "unit_id"
    t.string   "code"
    t.string   "db_source"
    t.string   "legacy_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "unit_langs", ["db_source", "legacy_id"], :name => "index_unit_langs_on_source_and_legacy_id"
  add_index "unit_langs", ["unit_id"], :name => "index_unit_langs_on_unit_id"

  create_table "unit_other_reference_numbers", :force => true do |t|
    t.integer  "unit_id"
    t.string   "other_reference_number"
    t.string   "qualifier"
    t.text     "note"
    t.string   "db_source"
    t.string   "legacy_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "unit_other_reference_numbers", ["db_source", "legacy_id"], :name => "index_unit_other_reference_numbers_on_source_and_legacy_id"
  add_index "unit_other_reference_numbers", ["unit_id"], :name => "index_unit_other_reference_numbers_on_unit_id"

  create_table "unit_urls", :force => true do |t|
    t.integer  "unit_id"
    t.string   "url"
    t.text     "note"
    t.integer  "position"
    t.string   "db_source"
    t.string   "legacy_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "unit_urls", ["db_source", "legacy_id"], :name => "index_unit_urls_on_source_and_legacy_id"
  add_index "unit_urls", ["unit_id"], :name => "index_unit_urls_on_unit_id"

  create_table "units", :force => true do |t|
    t.integer  "fond_id"
    t.integer  "root_fond_id"
    t.integer  "position",                               :default => 0
    t.integer  "sequence_number"
    t.string   "ancestry"
    t.integer  "ancestry_depth"
    t.string   "tsk",                       :limit => 5
    t.string   "reference_number"
    t.integer  "tmp_reference_number"
    t.string   "tmp_reference_string"
    t.text     "title"
    t.boolean  "given_title"
    t.integer  "folder_number"
    t.integer  "file_number"
    t.string   "sort_letter"
    t.integer  "sort_number"
    t.string   "unit_type"
    t.string   "medium"
    t.text     "content"
    t.text     "arrangement_note"
    t.text     "related_materials"
    t.string   "physical_type"
    t.text     "physical_description"
    t.string   "physical_container_type"
    t.string   "physical_container_title"
    t.string   "physical_container_number"
    t.string   "preservation"
    t.text     "preservation_note"
    t.text     "restoration"
    t.string   "access_condition"
    t.text     "access_condition_note"
    t.string   "use_condition"
    t.text     "use_condition_note"
    t.text     "note"
    t.integer  "created_by"
    t.integer  "updated_by"
    t.string   "db_source"
    t.string   "legacy_id"
    t.integer  "legacy_position"
    t.string   "legacy_sequence_number"
    t.string   "legacy_parent_unit_id"
    t.string   "legacy_parent_fond_id"
    t.string   "legacy_root_fond_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "units", ["ancestry"], :name => "index_units_on_ancestry"
  add_index "units", ["db_source", "legacy_id"], :name => "index_units_on_source_and_legacy_id"
  add_index "units", ["db_source", "legacy_parent_fond_id"], :name => "index_units_on_source_and_legacy_parent_fond_id"
  add_index "units", ["db_source", "legacy_parent_unit_id"], :name => "index_units_on_source_and_legacy_parent_unit_id"
  add_index "units", ["db_source", "legacy_root_fond_id"], :name => "index_units_on_source_and_legacy_root_fond_id"
  add_index "units", ["fond_id"], :name => "index_units_on_fond_id"
  add_index "units", ["root_fond_id"], :name => "index_units_on_root_fond_id"

  create_table "users", :force => true do |t|
    t.boolean  "active",                             :default => true, :null => false
    t.string   "email",                              :default => "",   :null => false
    t.string   "username"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "qualifier"
    t.string   "role"
    t.string   "encrypted_password",  :limit => 128, :default => "",   :null => false
    t.string   "password_salt",                      :default => "",   :null => false
    t.string   "remember_token"
    t.datetime "remember_created_at"
    t.integer  "group_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "users", ["group_id"], :name => "index_users_on_group_id"

  create_table "vocabularies", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "vocabularies", ["name"], :name => "index_vocabularies_on_name"

end
