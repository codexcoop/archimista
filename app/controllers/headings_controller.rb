class HeadingsController < ApplicationController
  helper_method :sort_column

  load_and_authorize_resource :except => [:ajax_list, :modal_new, :modal_link]

  def index
    terms
    conditions = params[:view] ? "heading_type = '#{params[:view]}'" : true

    @headings = Heading.accessible_by(current_ability, :read).
                paginate(:page => params[:page], 
                         :conditions => conditions, 
                         :order => sort_column + ' ' + sort_direction
                        )
  
    @units_counts = RelUnitHeading.count(
      "id",
      :joins => :heading,
      :conditions => {:heading_id => @headings.map(&:id)},
      :group => :heading_id
    )
  end

  def list
    terms
    term = params[:term] || ""

    unless params[:exclude].blank?
      exclude_condition = " AND id NOT IN (#{params[:exclude].join(',')})"
    end

    @headings = Heading.accessible_by(current_ability, :read).
      find(:all, :conditions => "(LOWER(heading_type) LIKE '%#{term}%'
                                  OR LOWER(name) LIKE '%#{term}%'
                                  OR LOWER(dates) LIKE '%#{term}%'
                                  OR LOWER(qualifier) LIKE '%#{term}%')
                                  #{exclude_condition}",
           :order => "name", :limit => 20)

    ActiveRecord::Base.include_root_in_json = false
    response = @headings.to_json(:methods => [:id, :value], :only => :methods)

    respond_to do |format|
      format.json { render :json => response }
    end
  end

  def show
    terms
    @heading = Heading.find(params[:id])
    @units = Unit.all(
     :include => :rel_unit_headings,
     :conditions => "rel_unit_headings.heading_id = #{@heading.id}"
    ).paginate(:page => params[:page], 
                :order => sort_column + ' ' + sort_direction
    )
  end
  
  def new
    terms
    @heading = Heading.new
  end

  def edit
    terms
    @heading = Heading.find(params[:id])
  end

  def create
    terms
    @heading = Heading.new(params[:heading]).tap do |heading|
      heading.group_id = current_user.group_id
    end

    if @heading.save
      redirect_to(headings_url, :notice => 'Lemma creato')
    else
      render :action => "new"
    end
  end

  def modal_new
    terms
    render :partial => 'headings/new_heading', :layout => false
  end

  def modal_link
    terms
    model = params[:related_entity].singularize.camelize.constantize
    @entity = model.find(params[:related_entity_id], :include => :headings)
    render :partial => 'headings/link_heading', :object => @entity.heading_ids, :layout => false
  end

  def modal_create
    @heading = Heading.find_or_initialize(params[:heading])

    model = params[:related_entity].singularize.camelize.constantize
    @entity = model.find(params[:related_entity_id])
    respond_to do |format|
      if @heading.new_record?
        @entity.headings.create(params[:heading])
        format.json { render :json => {:status => "success" }}
      else
        @entity.headings.push(@heading) unless @entity.headings.include? @heading
        format.json { render :json => {:status => "success" }}
      end
    end
  end

  def ajax_list
    model = params[:related_entity].singularize.camelize.constantize
    @entity = model.find(params[:related_entity_id], :include => :headings)
    render :partial => 'headings/list_for', :object => @entity.headings, :layout => false
  end

  def ajax_remove
    @heading = Heading.find(params[:heading_id])
    model = params[:related_entity].singularize.camelize.constantize
    @entity = model.find(params[:related_entity_id])
    @entity.headings.delete(@heading)

    respond_to do |format|
      if @entity.save
        format.json { render :json => {:status => "success"} }
      else
        format.json { render :json => {:status => "failure", :msg => 'Rimozione non riuscita'} }
      end
    end
  end

  def ajax_link
    @heading = Heading.find(params[:heading_id])
    model = params[:related_entity].singularize.camelize.constantize
    @entity = model.find(params[:related_entity_id])
    @entity.headings.push(@heading) unless @entity.headings.include? @heading
    respond_to do |format|
      format.json { render :json => {:status => "success"} }
    end
  end

  def update
    terms
    @heading = Heading.find(params[:id])

    if @heading.update_attributes(params[:heading])
      redirect_to(headings_url(:view => @heading.heading_type), :notice => 'Lemma aggiornato')
    else
      render :action => "edit"
    end
  end

  def destroy
    @heading = Heading.find(params[:id])
    @heading.destroy

    redirect_to(headings_url)
  end

  def import_csv
  end

  def preview_csv
    terms

    if params[:upload].present?
      begin
        @csv = FasterCSV.parse(params[:upload][:csv], :col_sep => ";", :headers => headers)
      rescue
        flash.now[:alert] = "CSV non valido"
        render :action => "import_csv"
      end
    else
      render :action => "import_csv"
    end
  end

  def save_csv
    terms
    if File.exist?(params[:filename])
      @file = File.new(params[:filename], "r")
      @csv = FasterCSV.new(@file, :col_sep => ";", :headers => headers)
      @csv.each do |row|
        @record = Heading.new(
          :heading_type => row[0],
          :name => row[1],
          :dates => row[2],
          :qualifier => row[3],
          :group_id => current_user.group_id
        )
        @record.save
      end
      redirect_to(headings_url, :notice => "Lemmi importati")
    else
      redirect_to(headings_url, :notice => "Si è verificato un errore durante l'importazione dei lemmi")
    end
  end


  private

  def sort_column
     params[:sort] || "heading_type, name"
  end

end
