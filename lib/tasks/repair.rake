namespace :repair do

  desc "Clear the relations of non-root fonds specific to root fonds"
  task :fonds_relations => :environment do
    @non_root_fonds = Fond.all(:conditions => "ancestry_depth > 0", :order => :ancestry)

    @non_root_fonds.each do |fond|
      puts "#{fond.id.to_s.rjust(5)} => #{fond.name}"
      fond.rel_custodian_fonds.clear
      fond.rel_project_fonds.clear
    end
  end

  desc "Clear the relations where foreign keys are NULL"
  task :null_relations => :environment do
    tables = {
      "rel_creator_creators" => ["creator_id", "related_creator_id"],
      "rel_creator_fonds" => ["creator_id", "fond_id"],
      "rel_creator_institutions" => ["creator_id", "institution_id"],
      "rel_creator_sources" => ["creator_id", "source_id"],
      "rel_custodian_fonds" => ["custodian_id", "fond_id"],
      "rel_custodian_sources" => ["custodian_id", "source_id"],
      "rel_fond_document_forms" => ["fond_id", "document_form_id"],
      "rel_fond_headings" => ["fond_id", "heading_id"],
      "rel_fond_sources" => ["fond_id", "source_id"],
      "rel_project_fonds" => ["project_id", "fond_id"],
      "rel_unit_headings" => ["unit_id", "heading_id"],
      "rel_unit_sources" => ["unit_id", "source_id"],
    }

    tables.each do |table, foreign_keys|
      puts "- #{table}"
      table.classify.constantize.delete_all("#{foreign_keys[0]} IS NULL OR #{foreign_keys[1]} IS NULL")
    end
  end

end
