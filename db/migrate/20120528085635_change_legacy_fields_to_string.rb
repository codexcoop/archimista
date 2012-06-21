class ChangeLegacyFieldsToString < ActiveRecord::Migration
  def self.up
    tables = ["creator_editors", "custodian_editors", "document_form_editors", "fond_editors", "institution_editors", "unit_editors"]
    tables.each do |table|
      change_column table.to_sym, :legacy_id, :string
    end
  end

  def self.down
    #irreversible migration
  end
end
