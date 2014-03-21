class GroupsController < ApplicationController
  helper_method :sort_column

  load_and_authorize_resource

  def index
    @groups = Group.accessible_by(current_ability, :manage).
                    all(:order => sort_column + ' ' + sort_direction)
  end

  def show
    @group = Group.find(params[:id])
  end

  def new
    @group = Group.new
  end

  def create
    @group = Group.new(params[:group])

    if @group.save
      redirect_to(groups_url, :notice => "Creato il gruppo: #{@group.name}")
    else
      render :action => "new"
    end
  end

  def edit
    @group = Group.find(params[:id])
  end

  def update
    @group = Group.find(params[:id])

    if @group.update_attributes(params[:group])
      redirect_to(groups_url, :notice => "Gruppo aggiornato.")
    else
      render :action => "edit"
    end
  end

  def destroy
    @group = Group.find(params[:id])
    @group.destroy

    redirect_to(groups_url, :notice => "Eliminato il gruppo: #{@group.name}")
  end

  private

  def sort_column
    params[:sort] || "created_at"
  end

end
