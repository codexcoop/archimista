class AddImportableFieldsToImport < ActiveRecord::Migration
  def self.up
    add_column :imports, :importable_type, :string
    add_column :imports, :importable_id, :integer
  end

  def self.down
    remove_column :imports, :importable_type
    remove_column :imports, :importable_id
  end
end
