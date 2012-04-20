class CustodiansController < ApplicationController
  helper_method :sort_column
  load_and_authorize_resource

  def index
    @custodians = Custodian.list.search(params[:q]).accessible_by(current_ability, :read).paginate(:page => params[:page], :order => sort_column + ' ' + sort_direction)
    terms
  end

  def list
    search_param  = [params[:term], params[:q]].find(&:present?)
    custodians    = Custodian.accessible_by(current_ability, :read).autocomplete_list(search_param)

    respond_to do |format|
      format.json { render :json => custodians.map(&:attributes) }
    end
  end

  def show
    @custodian = Custodian.find(params[:id])
  end

  def new
    @custodian = Custodian.new

    terms
    setup_relation_collections
  end

  def edit
    @custodian = Custodian.find(params[:id])
    terms
    setup_relation_collections
  end

  def create
    @custodian = Custodian.new(params[:custodian]).tap do|custodian|
      custodian.created_by = current_user.id
      custodian.updated_by = current_user.id
      custodian.group_id = current_user.group_id
    end

    @custodian.save
    setup_relation_collections

    if @custodian.valid?
      if params[:save_and_continue]
        redirect_to(edit_custodian_url(@custodian), :notice => 'Scheda creata')
      else
        redirect_to(@custodian, :notice => 'Scheda creata')
      end
    else
      terms
      render :action => "new"
    end
  end

  def update
    @custodian = Custodian.find(params[:id]).tap {|custodian| custodian.updated_by = current_user.id}
    @custodian.update_attributes(params[:custodian])
    setup_relation_collections

    if @custodian.valid?
      if params[:save_and_continue]
        redirect_to(edit_custodian_url(@custodian), :notice => 'Scheda aggiornata')
      else
        redirect_to(@custodian)
      end
    else
      terms
      render :action => "edit"
    end
  end

  def destroy
    @custodian = Custodian.find(params[:id])
    @custodian.destroy

    redirect_to(custodians_url)
  end

  private

  def setup_relation_collections
    return unless @custodian

    relation_collections  :related => "fonds", :through => "rel_custodian_fonds",
      :available => Fond.accessible_by(current_ability, :read).roots.unassigned_to_custodian(:unless => @custodian).active.count('id'),
      :suggested => Proc.new{
                      Fond.roots.active.
                           unassigned_to_custodian(:unless => @custodian).
                           scoped( :select => 'fonds.id, fonds.name', :order => "name" )
                    }

    relation_collections  :related => "sources", :through => "rel_custodian_sources"
  end

  def sort_column
    params[:sort] || "name"
    # segliere se fare query in più per sicurezza: Fond.column_names.include?(params[:sort]) ? params[:sort] : "name"
  end
end

