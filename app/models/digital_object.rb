class DigitalObject < ActiveRecord::Base

  # #include Rails.application.routes.url_helpers # for Rails 3
  include ActionController::UrlWriter

  cattr_reader :per_page
  @@per_page = 50

  belongs_to :attachable, :polymorphic => true
  belongs_to :updater,  :class_name => "User", :foreign_key => "updated_by"

  acts_as_list

  def scope_condition
    "attachable_type = '#{attachable_type}' AND attachable_id = #{attachable_id}"
  end

  before_create :generate_access_token

  # Paperclip
  has_attached_file :asset,
    :styles => { :large => '1280x1280>', :medium => '210x210>', :thumb => '130x130>' },
    :url => '/digital_objects/:access_token/:style.:extension',
    :default_url => "/images/missing-:style.jpg"

  validates_attachment_presence :asset

  validates_attachment_content_type :asset,
    :content_type => ["image/jpeg", "image/jpg", "image/pjpeg", "application/pdf", "video/mp4", "application/mp4", "video/mpeg4"]

  validates_attachment_size :asset, :less_than => 8.megabytes

  before_post_process :is_image?

  # Scopes
  named_scope :by_entity, lambda { |entity|
    { :conditions => { :attachable_type => entity } } if entity.present?
  }

  # Methods
  def self.is_enabled?
    begin
      img = "#{Rails.root}/public/images/image_magick.jpg"
      Paperclip.run("identify", '"'+img+'"') # :-/ I hate MS Win
    rescue
      return false
    end
    return true
  end

  def is_image?
    ["image/jpeg", "image/jpg", "image/pjpeg"].include?(asset.content_type)
  end

  def is_video?
    ["video/mp4", "application/mp4", "video/mpeg4"].include?(asset.content_type)
  end

  def to_jq_upload
    thumbnail_url = asset_content_type.include?("pdf") ? "/images/pdf-medium.png" : asset.url(:thumb)

    {
      "name" => read_attribute(:asset_file_name),
      "size" => read_attribute(:asset_file_size),
      "content_type" => read_attribute(:asset_content_type),
      "url" => asset.url(:original),
      "thumbnail_url" => thumbnail_url,
      "delete_url" => digital_object_path(self),
      "delete_type" => "DELETE",
      "title" => title,
      "description" => description
    }
  end

  private

  def generate_access_token
    self.access_token = Digest::SHA1.hexdigest("#{asset_file_name}#{Time.now.to_i}")
  end

  Paperclip.interpolates :access_token  do |attachment, style|
    attachment.instance.access_token
  end

end

