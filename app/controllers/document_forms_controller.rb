class DocumentFormsController < ApplicationController
  helper_method :sort_column
  load_and_authorize_resource

  def index
    @document_forms = DocumentForm.accessible_by(current_ability, :read).
                      paginate(:page => params[:page], :order => sort_column + ' ' + sort_direction)
  end

  def list
    search_param  = [params[:term], params[:q]].find(&:present?)
    document_forms  = DocumentForm.accessible_by(current_ability, :read).autocomplete_list(search_param)

    respond_to do |format|
      format.json { render :json => document_forms.map(&:attributes) }
    end
  end

  def show
    terms
    @document_form = DocumentForm.find(params[:id])
  end

  def new
    terms
    @document_form = DocumentForm.new

  end

  def edit
    terms
    @document_form = DocumentForm.find(params[:id])
  end

  def create
    terms
    @document_form = DocumentForm.new(params[:document_form]).tap do |document_form|
                      document_form.created_by = current_user.id
                      document_form.updated_by = current_user.id
                      document_form.group_id = current_user.group_id
                     end
    if @document_form.save
      redirect_to(edit_document_form_url(@document_form), :notice => 'Scheda creata')
    else
      render :action => "new"
    end
  end

  def update
    @document_form = DocumentForm.find(params[:id])

    if @document_form.update_attributes(params[:document_form])
      redirect_to(edit_document_form_url(@document_form), :notice => 'Scheda aggiornata')
    else
      render :action => "edit"
    end
  end

  def destroy
    @document_form = DocumentForm.find(params[:id])
    @document_form.destroy

    redirect_to(document_forms_url)
  end

  private

  def sort_column
    params[:sort] || "name"
  end

end

