class CreatorsController < ApplicationController
  helper_method :sort_column
  load_and_authorize_resource

  def index
    terms
    conditions = params[:view] ? "creator_type = '#{params[:view]}'" : ""

    @creators = Creator.list.search(params[:q]).accessible_by(current_ability, :read).paginate(:page => params[:page],
      :conditions => conditions,
      :order => lower_sort_column + ' ' + sort_direction,
      :include => :preferred_event)

    @counts_by_type = Creator.accessible_by(current_ability, :read).count("id", :group => :creator_type)
  end

  def list
    search_param  = [params[:term], params[:q]].find(&:present?)
    @creators = Creator.accessible_by(current_ability, :read).autocomplete_list(search_param)

    ActiveRecord::Base.include_root_in_json = false
    results = @creators.to_json(:methods => [:id, :value], :only => :methods)

    respond_to do |format|
      format.json { render :json => results }
    end
  end

  def show
    @creator = Creator.find(params[:id])
  end

  def new
    terms
    @creator = Creator.new
    params[:type] ||= 'C'
    @events = @creator.events_for_view
    setup_relation_collections
  end

  def edit
    @creator = Creator.find(params[:id])
    terms
    @events = @creator.events_for_view
    setup_relation_collections
  end

  def create
    @creator = Creator.new(params[:creator]).tap do |creator|
      creator.created_by = current_user.id
      creator.updated_by = current_user.id
      creator.group_id = current_user.group_id
    end
    @events = @creator.events.sort_by(&:order_date)
    @creator.save

    setup_relation_collections  # must be called after validation, otherwise records
    # marked for destruction won't be processed
    if @creator.valid?
      if params[:save_and_continue]
        redirect_to(edit_creator_url(@creator), :notice => 'Scheda creata')
      else
        redirect_to(@creator, :notice => 'Scheda creata')
      end
    else
      terms
      @events = @creator.events_for_view if @events.empty?
      render :action => "new"
    end
  end

  def update
    @creator = Creator.find(params[:id]).tap {|creator| creator.updated_by = current_user.id }
    @events = @creator.events.sort_by(&:order_date)
    @creator.update_attributes(params[:creator])
    setup_relation_collections  # must be called after validation, otherwise records
    # marked for destruction won't be processed

    if @creator.valid?
      if params[:save_and_continue]
        redirect_to(edit_creator_url(@creator), :notice => 'Scheda aggiornata')
      else
        redirect_to(@creator)
      end
    else
      terms
      @events = @creator.events_for_view if @events.empty?
      render :action => "edit"
    end
  end

  def destroy
    @creator = Creator.find(params[:id])
    @creator.destroy

    redirect_to(creators_url, :notice => "Scheda eliminata")
  end

  private

  def setup_relation_collections
    return unless @creator

    relation_collections  :related => "fonds", :through => "rel_creator_fonds",
      :available => Fond.accessible_by(current_ability, :read).roots.active.count('id'),
      :suggested => Proc.new{ Fond.roots.active.all( :select => 'id, name', :order => "name" ) }

    relation_collections  :related => "institutions", :through => "rel_creator_institutions",
      :available => Institution.accessible_by(current_ability, :read).count('id'),
      :suggested => Proc.new{ Institution.accessible_by(current_ability, :read).all(:select => 'id, name', :order => 'name') }

    relation_collections  :related => "related_creators", :through => "rel_creator_creators",
      :available => Creator.accessible_by(current_ability, :read).count('id'),
      :suggested => Proc.new{ Creator.accessible_by(current_ability, :read).sorted_suggested }

    relation_collections  :related => "sources", :through => "rel_creator_sources"

    @association_types = CreatorAssociationType.all(:select => 'id, association_type', :order => 'id')
  end

  def sort_column
    params[:sort] || "name"
  end

end

