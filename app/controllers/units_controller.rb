class UnitsController < ApplicationController
  helper_method :sort_column
  # FIXME: [1.x] iccd_unit subclass

  def gridview
    @fond                   = Fond.find(params[:fond_id], :select => "id, name, ancestry")
    @fond.go_to_unit        = Unit.find(flash[:go_to_unit_id]) if flash[:go_to_unit_id].present?
    @units_count            = @fond.active_descendant_units_count
    @vocabularies           = Unit.vocabularies_with_terms
    @root_fond              = @fond.root
    selected_attributes
  end

  def grid
    @fond                 = Fond.find(params[:fond_id], :select => "id, name, ancestry")
    @root_fond            = @fond.root
    @units                = Unit.units_for_grid(fond, params, selected_attributes)
    @display_sequence_numbers = Unit.display_sequence_numbers_of(@root_fond)

    hash_for_json_response = {
      :page         => @units.current_page,
      :records      => @units.total_entries,
      :rows         => Unit.jqgrid_rows(@units, selected_attributes, @display_sequence_numbers),
      :total        => @units.total_pages,
      :is_last_page => @units.current_page == @units.total_pages
    }

    respond_to do |format|
      format.json { render :json => hash_for_json_response }
    end
  end

  def add_rows
    first_created = Unit.bulk_create( params[:number_of_rows], params[:unit],
      :position_scope => [:fond_id, :ancestry],
      :sequence_number_scope => :fond_id )

    if first_created
      flash[:go_to_unit_id] = first_created.id
      flash[:notice] = "Aggiunte #{params[:number_of_rows]} unità"
    else
      flash[:bulk_failed] = true
      flash[:alert] = "Non è stato possibile creare le nuove unità"
    end

    redirect_to request.referrer.split("?")[0]

  end

  def remove_rows
    @fond = Fond.find(params[:fond_id])

    number_of_destroyed_records = 0
    valid_and_saved             = false

    Fond.transaction do
      number_of_destroyed_records = Unit.bulk_delete(params[:record_ids])
      valid_and_saved = @fond.update_full_external_sequence
    end

    if valid_and_saved && number_of_destroyed_records > 0
      flash[:notice] = "Eliminate #{number_of_destroyed_records} unità"
    else
      flash[:alert] = "Errore: non è stato possibile rimuovere alcuna unità"
    end
    # OPTIMIZE: rivedere redirect: un po' spiazzante quando l'azione è innescata da page > 1
    redirect_to request.referrer
  end

  def reorder_rows
    @root_fond = Fond.find(params[:fond_id]).root
    options = Unit.build_order_options(params['reorder_attributes'])
    filter = params['filter_ids']

    valid_and_saved = false
    if options
      valid_and_saved = @root_fond.rebuild_external_sequence_by( options[:order],
        { :joins => options[:joins],
          :conditions => options[:conditions] },
        filter )
    end

    if valid_and_saved
      flash[:notice] = "Ordine delle unità aggiornato"
    else
      flash[:alert] = "Errore durante l'aggiornamento dell'ordine delle unità"
    end

    redirect_to request.referrer
  end

  def classify
    if Unit.classify(params[:record_ids], params[:new_fond_id])
      new_fond_name = Fond.find(params[:new_fond_id], :select => "name").name

      count = 0
      root_unit_ids = Unit.find(params[:record_ids]).select {|r| r.ancestry_depth == 0}
      root_unit_ids.each do |u|
        count += u.subtree_ids.count
      end

      # OPTIMIZE: singolare/plurale nel notice
      flash[:notice] = "#{count} unità classificate sotto il livello: <strong>#{new_fond_name}</strong>"
    else
      flash[:alert] = "Errore durante la classificazione"
    end

    respond_to do |format|
      format.json { render :json => {:new_location => request.referrer} }
    end
  end

  def move
    @unit = Unit.find(params[:id])
    @siblings = @unit.siblings.all(:conditions => "fond_id = #{@unit.fond_id}", :order => :position).delete_if{|e| e.id == @unit.id}
    @display_sequence_numbers = Unit.display_sequence_numbers_of(@unit.fond.root)
    render :partial => 'units/move', :locals => {:units => @siblings}, :object => @unit, :layout => false
  end

  def move_up
    @unit = Unit.find(params[:id])
    @parent = @unit.parent
    @unit.ancestry = @parent.ancestry
    @unit.ancestry_depth = @parent.ancestry_depth
    @unit.position = Unit.prepare_position_by('position DESC').first(:conditions => {:ancestry => @parent.ancestry}).position + 1
    @unit.save

    Unit.descendants_of(@parent).all(:order => :position).each_with_index do |unit, index|
      unit.position = index + 1
      unit.save
    end

    Fond.find(@unit.root_fond_id).rebuild_external_sequence_by('position')
    flash[:notice] = "Unità spostata correttamente"
    redirect_to :back
  end

  def move_down
    @unit = Unit.find(params[:id])
    @old_parent = @unit.parent
    @new_parent = Unit.find(params[:new_parent_id])
    @unit.ancestry = @new_parent.ancestry.blank? ? @new_parent.id.to_s : @new_parent.ancestry+'/'+@new_parent.id.to_s
    @unit.ancestry_depth = @unit.ancestry_depth + 1
    @unit.position = Unit.prepare_position_by('position DESC').first(:conditions => {:ancestry => @new_parent.ancestry}).position + 1
    @unit.save

    if @old_parent.present? && @old_parent.has_children?
      Unit.descendants_of(@old_parent).all(:order => :position).each_with_index do |unit, index|
        unit.position = index + 1
        unit.save
      end
    end

    Fond.find(@unit.root_fond_id).rebuild_external_sequence_by('position')

    flash[:notice] = "Unità spostata correttamente"
    redirect_to :back
  end

  def preferred_event
    @unit = Unit.find(params[:id])
    @events = @unit.events_for_view

    render :template => 'units/preferred_event', :layout => false
  end

  def update_event
    @unit = Unit.find(params[:id], :include => :events)
    @unit.attributes = params[:unit]

    respond_to do |format|
      if @unit.save
        preferred_event = @unit.events.to_a.find(&:preferred)
        hash_for_json_response =  preferred_event.
          attributes.
          merge({:full_display_date => preferred_event.full_display_date, :status => "success"})
        format.json { render :json => hash_for_json_response }
      else
        format.json { render :json => {:status => "failure", :msg => @unit.errors.to_json }}
      end
    end
  end

  def textfield_form
    @unit = Unit.find(params[:id])
    @field = params[:field]

    render :partial => 'units/gridview_textfield', :locals => {:field => @field}, :layout => false
  end

  def index
    fond

    if @fond
      @vocabularies = Unit.vocabularies_with_terms
      @root_fond = @fond.root
      @display_sequence_numbers = Unit.display_sequence_numbers_of(@root_fond)

      @units =  if @fond.is_root?
        @fond.descendant_units
      else
        @fond.units
      end.
        search(params[:q]).
        paginate( :page => params[:page],
        :select => "units.id, units.fond_id, units.position, units.sequence_number,
                    units.ancestry, units.ancestry_depth, units.tsk,
                    units.reference_number, units.tmp_reference_number, units.title,
                    unit_events.start_date_display AS preferred_start_date_display,
                    unit_events.end_date_display AS preferred_end_date_display,
                    unit_events.order_date AS preferred_order_date".squish,
        :joins => "LEFT OUTER JOIN unit_events ON units.id = unit_events.unit_id",
        # :include => [:fond], # OPTIMIZE: esaminare attentamente. Forse migliora performance.
        :conditions => ["units.sequence_number IS NOT NULL AND (unit_events.preferred = ? OR unit_events.preferred IS NULL)", true],
        :order => sort_column + ' ' + sort_direction )
    else
      redirect_to fonds_url
    end
  end

  def show_iccd
    @unit = Unit.find(params[:id])

    #OPTIMIZE: rivedere variabili di istanza e queries - forse events non serve
    @full_path = @unit.full_path
    @root_fond = @full_path.first
    @events = @unit.events_for_view
  end

  def show
    @unit = Unit.find(params[:id])

    #OPTIMIZE: rivedere variabili di istanza e queries - forse events non serve
    @full_path = @unit.full_path
    @root_fond = @full_path.first
    # @events = @unit.events_for_view
    respond_to do |format|
      format.html
      format.json { render :json => @unit.attributes }
    end
  end

  def render_full_path
    unit =  if params[:id] == 'new' || params[:id].to_i == 0
      Unit.new
    else
      Unit.find(params[:id])
    end

    unit.fond_id  = params[:fond_id]
    full_path     = unit.full_path

    render :partial => "units/full_path", :locals => {:unit => unit, :full_path => full_path}
  end

  def list_oa_mtc
    term = params[:term] || ""
    @iccd_terms_oa_mtc = IccdTermsOaMtc.all(:select => "distinct mtc as value",
      :conditions => ["LOWER(mtc) LIKE ?", "#{term}%"],
      :order => 'value',
      :limit => 10
    )
    respond_to do |format|
      format.json { render :json => @iccd_terms_oa_mtc.map(&:attributes) }
    end
  end

  def list_oa_ogtd
    term = params[:term] || ""
    @iccd_terms_oa_ogtd = IccdTermsOaOgtd.all(:select => "ogtd, ogtt",
      :conditions => ["LOWER(ogtd) LIKE ?", "#{term}%"],
      :order => 'ogtd, ogtt',
      :limit => 10
    )

    ActiveRecord::Base.include_root_in_json = false
    response = @iccd_terms_oa_ogtd.to_json(:methods => [:value], :only => :methods)

    respond_to do |format|
      format.json { render :json =>  response }
    end
  end

  def list_bdm_ogtd
    term = params[:term] || ""
    @iccd_terms_bdm_ogtd = IccdTermsBdmOgtd.all(:select => "ogtd as value",
      :conditions => ["LOWER(ogtd) LIKE ?", "#{term}%"],
      :order => 'ogtd',
      :limit => 10
    )
    ActiveRecord::Base.include_root_in_json = false
    response = @iccd_terms_bdm_ogtd.to_json(:methods => [:value], :only => :methods)

    respond_to do |format|
      format.json { render :json =>  response }
    end
  end

  def list_bdm_mtct
    term = params[:term] || ""
    @iccd_terms_bdm_mtct = IccdTermsBdmMtct.all(:select => "mtct as value",
      :conditions => ["LOWER(mtct) LIKE ?", "#{term}%"],
      :order => 'mtct',
      :limit => 10
    )
    ActiveRecord::Base.include_root_in_json = false
    response = @iccd_terms_bdm_mtct.to_json(:methods => [:value], :only => :methods)

    respond_to do |format|
      format.json { render :json =>  response }
    end
  end

  def list_bdm_mtcm
    term = params[:term] || ""
    @iccd_terms_bdm_mtcm = IccdTermsBdmMtcm.all(:select => "mtcm as value",
      :conditions => ["LOWER(mtcm) LIKE ?", "#{term}%"],
      :order => 'mtcm',
      :limit => 10
    )
    ActiveRecord::Base.include_root_in_json = false
    response = @iccd_terms_bdm_mtcm.to_json(:methods => [:value], :only => :methods)

    respond_to do |format|
      format.json { render :json =>  response }
    end
  end

  # OPTIMIZE: prevenire accesso via indirizzo a unit_id SSU.
  # Comunque il modello solleva giustamente errore e impedisce di creare U di livello 3
  def new
    terms
    iccd_terms
    langs
    fond
    parent

    @unit = if @fond
      Unit.new(:fond_id => @fond.id)
    elsif @parent
      Unit.new(:parent_id => @parent.id, :fond_id => @parent.fond_id)
    end
    @full_path = @unit.full_path
    @events = @unit.events_for_view

    setup_relation_collections
  end

  def new_iccd
    types = %w[F S D OA BDM]

    if params[:t] && types.include?(params[:t].upcase)
      @iccd_type = params[:t].upcase
    else
      @iccd_type = "F"
    end

    terms
    iccd_terms
    langs
    fond
    parent

    @unit = if @fond
      Unit.new(:fond_id => @fond.id, :tsk => flash[:tsk])
    elsif @parent
      @fond = Fond.find(@parent.fond_id)
      Unit.new(:parent_id => @parent.id, :fond_id => @parent.fond_id, :tsk => flash[:tsk])
    end
    @full_path = @unit.full_path
    @events = @unit.events_for_view

    #OPTIMIZE valutare se fare metodo in modello
    @rel_custodian = RelCustodianFond.find_by_fond_id(@fond.id)
    @custodian = Custodian.find(@rel_custodian.custodian_id) if @rel_custodian.present?

    setup_relation_collections
  end

  def edit_iccd
    types = %w[F S D OA BDM]

    if params[:t] && types.include?(params[:t].upcase)
      @iccd_type = params[:t].upcase
    else
      @iccd_type = "F"
    end

    terms
    iccd_terms
    langs
    @unit = Unit.find(params[:id])
    @fond = Fond.find(@unit.root_fond_id)

    #OPTIMIZE valutare se fare metodo in modello
    @rel_custodian = RelCustodianFond.find_by_fond_id(@fond.id)
    @custodian = Custodian.find(@rel_custodian.custodian_id) if @rel_custodian.present?
    #setup_relation_collections

    #OPTIMIZE: rivedere variabili di istanza e queries
    @full_path = @unit.full_path
    @root_fond = @full_path.first
    @events = @unit.events_for_view
  end

  def edit
    terms
    iccd_terms
    langs
    @unit = Unit.find(params[:id])

    setup_relation_collections

    #OPTIMIZE: rivedere variabili di istanza e queries
    @full_path = @unit.full_path
    @root_fond = @full_path.first
    @events = @unit.events_for_view
  end

  def create
    @unit = Unit.new(params[:unit]).tap do |unit|
      unit.created_by = current_user.id
      unit.updated_by = current_user.id
    end
    @full_path  = @unit.full_path
    @events     = @unit.events.sort_by(&:order_date)

    setup_relation_collections

    if @unit.save
      if params[:save_and_continue]
        redirect_to(edit_unit_url(@unit), :notice => 'Scheda creata')
      elsif params[:save_and_add_new]
        redirect_to(new_fond_unit_url(@unit.fond_id), :notice => 'Scheda creata')
      elsif params[:save_and_continue_iccd]
        flash[:notice] = 'Scheda creata'
        flash[:tsk] = @unit.tsk
        redirect_to(edit_iccd_unit_url(@unit) + "?t=#{@unit.tsk}")
      elsif params[:save_and_add_new_iccd]
        flash[:notice] = 'Scheda creata'
        flash[:tsk] = @unit.tsk
        redirect_to(new_iccd_fond_units_path(@unit.fond_id) + "?t=#{@unit.tsk}")
      elsif params[:show_iccd]
        redirect_to(show_iccd_unit_path(@unit))
      else
        redirect_to(@unit)
      end
    else
      terms
      iccd_terms
      langs
      @events = @unit.events_for_view if @events.empty?
      render :action => "new"
    end
  end

  def update
    @unit             = Unit.find(params[:id])
    @unit.updated_by  = current_user.id

    @full_path        = @unit.full_path
    @events           = @unit.events.sort_by(&:order_date)
    setup_relation_collections

    valid_and_saved = false
    Unit.transaction do
      @unit.update_attributes(params[:unit])
      valid_and_saved = @unit.update_sequence_for_structural_root if @unit.valid?
    end

    # TODO: [Luca] vedere se creare action specfiche visto che questa è diventata un paciugo
    respond_to do |format|
      if valid_and_saved
        @root_fond = @unit.fond.root
        Unit.bulk_update_fonds_units_count(@root_fond.subtree_ids)

        if request.xhr?
          format.json { render :json => {:status => "success"} }
        else
          if params[:save_and_continue]
            format.html { redirect_to(edit_unit_url(@unit), :notice => 'Scheda aggiornata') }
          elsif params[:save_and_add_new]
            target_link = if @unit.is_root?
              new_fond_unit_url(@unit.fond_id)
            else
              new_unit_child_url(@unit.parent.id)
            end
            format.html { redirect_to(target_link) }
          elsif params[:save_and_continue_iccd]
            flash[:notice] = 'Scheda creata'
            format.html { redirect_to(edit_iccd_unit_path(@unit) + "?t=#{@unit.tsk}") }
          elsif params[:save_and_add_new_iccd]
            flash[:notice] = 'Scheda creata'
            flash[:tsk] = @unit.tsk
            format.html { redirect_to(new_iccd_fond_units_path(@unit.fond_id) + "?t=#{@unit.tsk}") }
          elsif params[:show_iccd]
            format.html { redirect_to(show_iccd_unit_path(@unit))}
          else
            format.html { redirect_to(@unit) }
          end
        end
      else
        terms
        iccd_terms
        langs
        # OPTIMIZE: dry!!!
        @full_path = @unit.full_path
        @root_fond = @full_path.first
        @events = @unit.events_for_view if @events.empty?
        format.html { render :action => "edit" }
      end
    end
  end

  def ajax_update
    attribute, value = *params[:unit].to_a.flatten[0..1]
    Unit.update_all(["#{attribute} = ?", value], {:id => params[:id]})

    respond_to do |format|
      format.json { render :json => {:status => 'success'} }
    end
  end

  def destroy
    @unit = Unit.find(params[:id])
    @unit.destroy

    # OPTIMIZE: rivedere redirect
    redirect_to fond_units_url(@unit.root_fond_id), :notice => "Scheda eliminata"
  end

  private

  def fond
    @fond ||= Fond.find(params[:fond_id]) if params[:fond_id].present?
  end

  def parent
    @parent ||= Unit.find(params[:unit_id]) if params[:unit_id].present?
  end

  def setup_relation_collections
    return unless @unit

    relation_collections  :related => "sources", :through => "rel_unit_sources"
    relation_collections  :related => "headings", :through => "rel_unit_headings",
      :available => Heading.accessible_by(current_ability, :read).count('id')
  end

  def sort_column
    params[:sort] || "sequence_number"
  end

  def selected_attributes
    return @selected_attributes if defined? @selected_attributes

    @selected_attributes = if params[:selected_attributes].present?
      cookies.permanent[:selected_attributes] = Marshal.dump(params[:selected_attributes])
      params[:selected_attributes]
    elsif cookies[:selected_attributes].present?
      Marshal.load(cookies[:selected_attributes])
    end
    @selected_attributes
  end

end

