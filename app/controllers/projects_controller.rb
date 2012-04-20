class ProjectsController < ApplicationController

  load_and_authorize_resource

  def index
    @projects = Project.accessible_by(current_ability, :read).paginate :page => params[:page], :order => "name"
  end

  def list
    search_param  = [params[:term], params[:q]].find(&:present?)
    projects      = Project.accessible_by(current_ability, :read).autocomplete_list(search_param)

    respond_to do |format|
      format.json { render :json => projects.map(&:attributes) }
    end
  end

  def show
    @project = Project.find(params[:id])
  end

  def new
    @project = Project.new
    terms
    setup_relation_collections
  end

  def edit
    @project = Project.find(params[:id])
    terms
    setup_relation_collections
  end

  def create
    @project = Project.new(params[:project]).tap do |project|
      project.created_by = current_user.id
      project.updated_by = current_user.id
      project.group_id = current_user.group_id
    end
    @project.save
    setup_relation_collections

    if @project.valid?
      if params[:save_and_continue]
        redirect_to(edit_project_url(@project), :notice => 'Scheda creata')
      else
        redirect_to(@project, :notice => 'Scheda creata')
      end
    else
      terms
      render :action => "new"
    end
  end

  def update
    @project = Project.find(params[:id]).tap {|project| project.updated_by = current_user.id}
    @project.update_attributes(params[:project])
    setup_relation_collections

    if @project.valid?
      if params[:save_and_continue]
        redirect_to(edit_project_url(@project), :notice => 'Scheda aggiornata')
      else
        redirect_to(@project, :notice => 'Scheda aggiornata')
      end
    else
      terms
      render :action => "edit"
    end
  end

  def destroy
    @project = Project.find(params[:id])
    @project.destroy

    redirect_to(projects_url, :notice => 'Scheda eliminata')
  end

  private

  def setup_relation_collections
    return unless @project
    relation_collections  :related => "fonds", :through => "rel_project_fonds",
      :available => Fond.accessible_by(current_ability, :read).roots.active.count('id'),
      :suggested => Proc.new{
      Fond.roots.active.scoped( :select => 'id, name', :order => "name" )
    }
  end

end

