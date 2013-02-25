class ImportsController < ApplicationController
  load_and_authorize_resource

  def index
    @imports = Import.accessible_by(current_ability, :read).all(:include => [:importable], :conditions => {:deletable => true}, :order => "created_at DESC")
  end

  def new
    @import = Import.new
  end

  def create
    if params[:import].present?
      @import = Import.new(params[:import])
      @import.user_id = current_user.id
      @import.group_id = current_user.group_id
      @import.identifier = Digest::SHA1.hexdigest("#{Time.now}")

      if @import.save
        begin
          @import.is_valid_file?
        rescue Exception => e
          @import.delete_tmp_files
          @import.delete
          redirect_to new_import_url, :alert => e.message
          return
        end

        if @import.import_aef_file(current_user)
          @import.delete_tmp_files
          @import.update_attributes :importable_id => @import.importable_id, :importable_type => @import.importable_type
          redirect_to imports_url, :notice => "File importato correttamente."
        else
          @import.delete_tmp_files
          @import.delete
          redirect_to imports_url, :alert => "Si è verificato un errore durante l'importazione del file <code>aef</code>."
        end

      else
        redirect_to imports_url, :alert => "Si è verificato un errore durante il salvataggio del file <code>aef</code>."
      end
    else
      render :action => "new"
    end
  end

  def destroy
    @import = Import.find(params[:id])
    respond_to do |format|
      if @import.wipe_all_related_records
        @import.destroy
        format.json { render :json => {:status => "success"} }
      else
        format.json { render :json => {:status => "failure", :msg => "Si è verificato un errore"} }
      end
    end
  end
end
