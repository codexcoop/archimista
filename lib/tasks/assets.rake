namespace :assets do
  desc "Remove compiled assets"
  task :clean do
    public_asset_path = File.join(Rails.public_path, 'assets')
    rm_rf Dir.glob("#{public_asset_path}/*"), :secure => true
  end
end