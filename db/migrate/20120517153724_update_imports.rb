class UpdateImports < ActiveRecord::Migration
  def self.up
    imports = Import.all
    imports.each do |import|
      import.importable_type = 'Fond'
      import.importable_id = Fond.all(:select => :id, :conditions => "db_source = '#{import.identifier}' AND ancestry IS NULL").first.id
      import.save
    end
  end

  def self.down
  end
end
