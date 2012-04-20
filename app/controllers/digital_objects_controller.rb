class DigitalObjectsController < ApplicationController
  helper_method :sort_column
  before_filter :require_image_magick, :except => [:disabled]
  load_and_authorize_resource

  def all
    @digital_objects = DigitalObject.accessible_by(current_ability, :read).
                                     paginate(:page => params[:page],
                                     :order => sort_column + ' ' + sort_direction)
  end

  # Polymorphic association - nested resource
  # Riferimento: http://asciicasts.com/episodes/154-polymorphic-association
  def index
    @attachable = find_attachable
    @digital_objects = @attachable.digital_objects.accessible_by(current_ability, :read).
                                   paginate(:page => params[:page],
                                   :order => "position")
  end

  def new
    @attachable = find_attachable
    @digital_object = DigitalObject.new
  end

  def edit
    @attachable = find_attachable
    @digital_object = DigitalObject.find(params[:id])
  end

  def create
    @attachable = find_attachable
    @digital_object = @attachable.digital_objects.build(params[:digital_object]).tap do |digital_object|
      digital_object.created_by = current_user.id
      digital_object.updated_by = current_user.id
      digital_object.group_id = current_user.group_id
    end

    if @digital_object.save
      flash[:notice] = "Oggetto digitale creato"
      redirect_to polymorphic_url([@attachable, "digital_objects"])
    else
      render :action => "new"
    end
  end

  def update
    @attachable = find_attachable
    @digital_object = DigitalObject.find(params[:id]).tap do |digital_object|
      digital_object.updated_by = current_user.id
    end

    if @digital_object.update_attributes(params[:digital_object])
      flash[:notice] = "Oggetto digitale modificato"
      redirect_to polymorphic_url([@attachable, "digital_objects"])
    else
      render :action => "edit"
    end
  end

  def destroy
    @digital_object = DigitalObject.find(params[:id])
    @digital_object.destroy

    redirect_to request.referrer, :notice => "Oggetto digitale eliminato"
  end

  private

  def find_attachable
    params.each do |name, value|
      if name =~ /(.+)_id$/
        return $1.classify.constantize.find(value)
      end
    end
    nil
  end

  def sort_column
    params[:sort] || "asset_file_name"
    # segliere se fare query in più per sicurezza: Creator.column_names.include?(params[:sort]) ? params[:sort] : "name"
  end

  def require_image_magick
    unless IM_ENABLED
      redirect_to disabled_digital_objects_url
    end
  end

end
