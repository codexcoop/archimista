namespace :db do

  # NOTE: nella versione 1.0 NON si carica Activity (activities.json), in quanto i termini sono in inglese.
  def models
    [ Group, User,
      Vocabulary, Term, IccdVocabulary, IccdTerm,
      CreatorAssociationType, CreatorCorporateType, CustodianType, SourceType,
      Place, Lang,
      IccdTermsOaMtc, IccdTermsOaOgtd, IccdTermsBdmOgtd, IccdTermsBdmMtct, IccdTermsBdmMtcm ]
  end

  def truncate_table(table)
    begin
      ActiveRecord::Base.connection.execute("TRUNCATE TABLE #{table};")
    rescue
      table.classify.constantize.delete_all
    end

    begin
      ActiveRecord::Base.connection.execute("ALTER SEQUENCE #{table}_id_seq RESTART WITH 1")
    rescue
      nil
    end
  end

  desc "Import db/seeds/*.json"
  task :seed => :environment do
    Logger.new(STDOUT, ActiveRecord::Base.logger)

    puts "Importing db/seeds/*.json"
    # NOTE: In order to skip User and Group, the array of models must be a local variable.
    # A call to "models" only invokes the method (therefore the whole array).
    m = models
    if User.all.any?
      m.delete(User)
      m.delete(Group)
      puts "Skipping User and Group"
    end

    m.each do |model|
      table = model.to_s.tableize
      path = File.join(Rails.root, "/db/seeds/#{table}.json")
      puts "- #{table}"

      truncate_table(table)

      lines = File.open(path).enum_for(:each_line)

      lines.each_slice(3000) do |lines_batch|
        model.transaction do
          lines_batch.each do |line|
            next if line.blank?
            object = model.new.from_json line.strip
            object.save!
          end
        end
      end
    end
  end

  namespace :seed do
    desc "Create db/seeds/*.json"
    task :create => :environment do
      puts "Creating files in db/seeds"
      models.each do |model|
        table = model.to_s.tableize
        path = File.join(Rails.root, "/db/seeds/#{table}.json")
        puts "- #{table}"

        objects = model.find(:all, :order => "id")
        ActiveRecord::Base.include_root_in_json = false
        File.delete(path) if File.exist?(path)
        File.open(path, "w") do |f|
          objects.each do |object|
            f.write(object.to_json(:except => [ :id, :created_at, :updated_at]))
            f.write("\r\n")
          end
        end
      end
    end

    desc "Truncate the seed data loaded from db/seeds/*.json"
    task :truncate => :environment do
      models.each do |model|
        table = model.to_s.tableize
        truncate_table(table)
      end
    end
  end

end

