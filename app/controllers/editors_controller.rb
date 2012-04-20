class EditorsController < ApplicationController
  load_and_authorize_resource

  def index
    @editors = Editor.accessible_by(current_ability, :read).paginate :page => params[:page], :order => 'last_name, first_name'
  end

  def show
    @editor = Editor.find(params[:id])
  end

  def new
    @editor = Editor.new
  end

  def edit
    @editor = Editor.find(params[:id])
  end

  def create
    @editor = Editor.new(params[:editor]).tap do |editor|
      editor.created_by = current_user.id
      editor.updated_by = current_user.id
      editor.group_id = current_user.group_id
    end

    if @editor.save
      redirect_to(editors_url, :notice => 'Scheda creata')
    else
      render :action => "new"
    end
  end

  def update
    @editor = Editor.find(params[:id])

    if @editor.update_attributes(params[:editor])
      redirect_to(editors_url, :notice => 'Scheda aggiornata')
    else
      render :action => "edit"
    end
  end

  def destroy
    @editor = Editor.find(params[:id])
    @editor.destroy

    redirect_to(editors_url)
  end

  def modal_new
    render :partial => 'editors/new_editor', :layout => false
  end

  def modal_create
    @editor = Editor.new(params[:editor]).tap do |editor|
      editor.created_by = current_user.id
      editor.updated_by = current_user.id
      editor.group_id = current_user.group_id
    end
    respond_to do |format|
      if @editor.save
        format.json { render :json => {:status => "success", :msg => "Scheda creata"} }
      else
        format.json { render :json => {:status => "failure", :msg => "Compilatore già presente"} }
      end
    end
  end
=begin
  def ajax_create
    @editor = Editor.new(params[:editor])
    respond_to do |format|
      if @editor.save
        format.json { render :json => {:status => "success", :id => "#{@editor.id}", :value => "#{@editor.value}"} }
      else
        format.json { render :json => {:status => "failure", :msg => "Compilatore già presente"} }
      end
    end
  end

  def list
    terms
    @editors = Editor.accessible_by(current_ability, :read).autocomplete_list(params[:term])

    ActiveRecord::Base.include_root_in_json = false
    response = @editors.to_json(:methods => [:id, :value], :only => :methods)

    respond_to do |format|
      format.json { render :json => response }
    end
  end
=end

  def list
    term = params[:term] || ""
    unless params[:exclude].blank?
      exclude_condition = " AND id NOT IN (#{params[:exclude].join(',')})"
    end

    @fonds = Editor.accessible_by(current_ability, :read).
      find(:all, :select => "id, first_name, last_name",
      :conditions => "CONCAT_WS(' ', first_name, last_name) LIKE '%#{term}%'#{exclude_condition}",
      :order => "first_name, last_name", :limit => 10)

    ActiveRecord::Base.include_root_in_json = false
    response = @fonds.to_json(:methods => [:id, :value], :only => :methods)

    respond_to do |format|
      format.json { render :json => response }
    end
  end

end
