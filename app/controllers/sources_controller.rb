class SourcesController < ApplicationController
  load_and_authorize_resource

  def index
    @sources = Source.accessible_by(current_ability, :read).search(params[:q]).
      paginate(:page => params[:page], :order => "short_title", :include => :source_type)
  end

  def list
    sources = Source.accessible_by(current_ability, :read).autocomplete_list(params[:term])

    respond_to do |format|
      format.html do
        render  :partial => "shared/relations/livesearch/results",
                :locals => {:sources => sources,
                            :excluded_ids => [],
                            :selected_label_short => lambda{|source| h(source.short_title)},
                            :selected_label_full  => lambda{|source, builder| builder.formatted_source(source)} }
      end
      format.json { render :json => sources.map(&:attributes) }
    end
  end

  def show
    @source = Source.find(params[:id])
  end

  def new
    params[:type] = 1 unless params[:type].present?
    @source = Source.new(:source_type_code => params[:type])
    terms
  end

  def edit
    @source = Source.find(params[:id])
    @source.source_type_code = params[:type] if params[:type].present?
    terms
  end

  def create
    @source = Source.new(params[:source]).tap do |source|
      source.created_by = current_user.id
      source.updated_by = current_user.id
      source.group_id = current_user.group_id
    end

    if @source.save
      redirect_to(edit_source_url(@source), :notice => 'Scheda creata')
    else
      terms
      render :action => "new"
    end
  end

  def update
    @source = Source.find(params[:id]).tap do |source|
      source.updated_by = current_user.id
    end

    if @source.update_attributes(params[:source])
      redirect_to(edit_source_url(@source), :notice => 'Scheda aggiornata')
    else
      terms
      render :action => "edit"
    end
  end

  def destroy
    @source = Source.find(params[:id])
    @source.destroy

    redirect_to(sources_url)
  end

end

