class ExportsController < ApplicationController

  def index
    @fonds = Fond.list.
      roots.
      accessible_by(current_ability, :read).
      active.
      default_order

    @custodians = Custodian.export_list.accessible_by(current_ability, :read)
    @projects = Project.export_list.accessible_by(current_ability, :read)

    if params[:target_id].present? && params[:target_class].present?
      suffix = Time.now.strftime("%Y%m%d%H%M%S")

      @export = Export.new
      @export.metadata_file = Export::TMP_EXPORTS + "/metadata-#{suffix}.json"
      @export.data_file = Export::TMP_EXPORTS + "/data-#{suffix}.json"
      @export.dest_file = "#{Rails.root}/public/downloads/archimista-#{suffix}.aef"
      @export.target_id = params[:target_id]
      @export.target_class = params[:target_class]
      @export.mode = params[:mode]
      @export.group_id = current_user.group_id
      @export.create_export_file

      respond_to do |format|
        format.json { render :json => @export }
      end
    end
  end

  def download
    #File.delete("#{Export::TMP_EXPORTS}/#{params[:data]}")
    #File.delete("#{Export::TMP_EXPORTS}/#{params[:meta]}")
    file = "#{Rails.root}/public/downloads/#{params[:file]}"
    send_file(file)
  end

end

