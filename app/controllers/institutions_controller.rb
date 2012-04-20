class InstitutionsController < ApplicationController
  load_and_authorize_resource

  def index
    terms
    @institutions = Institution.accessible_by(current_ability, :read).paginate :page => params[:page], :order => 'lower(name)'
  end

  def list
    @institutions = Institution.accessible_by(current_ability, :read).all(:select => "id, name AS value",
      :conditions => ["LOWER(name) LIKE ?", "%#{params[:term]}%"],
      :order => 'name')

    respond_to do |format|
      format.json { render :json => @institutions.map(&:attributes) }
    end
  end

  def show
    terms
    @institution = Institution.find(params[:id])
  end

  def new
    terms
    @institution = Institution.new

  end

  def edit
    terms
    @institution = Institution.find(params[:id])
  end

  def create
    terms
    @institution = Institution.new(params[:institution]).tap do |institution|
                       institution.created_by = current_user.id
                       institution.updated_by = current_user.id
                       institution.group_id = current_user.group_id
                      end

    if @institution.save
      redirect_to(@institution, :notice => 'Scheda creata')
    else
      render :action => "new"
    end
  end

  def update
    @institution = Institution.find(params[:id])

    if @institution.update_attributes(params[:institution])
      redirect_to(@institution, :notice => 'Scheda aggiornata')
    else
      render :action => "edit"
    end
  end

  def destroy
    @institution = Institution.find(params[:id])
    @institution.destroy

    redirect_to(institutions_url)
  end

end

