#FIXME: custodian report => report vuoto se manca progetto
#TODO: valutare l'tilizzo di simple_format nelle viste.
class ReportsController < ApplicationController
  def index
    @fonds = Fond.list.
      roots.
      accessible_by(current_ability, :read).
      active.
      default_order

    # TODO: al momento l'interfaccia gestisce massimo 100 record. Fare
    # live_search (anziché paginate) ?
    @custodians = Custodian.export_list.accessible_by(current_ability, :read)
    @projects = Project.export_list.accessible_by(current_ability, :read)

    if params[:q].present? && params[:f].present?
      @fond = Fond.find(params[:f])
      if @fond
        redirect_to :action => 'dashboard', :id => @fond
      end
    end
    if params[:q].present? && params[:c].present?
      @custodian = Custodian.find(params[:c])
      if @custodian
        redirect_to :action => 'custodian', :id => @custodian
      end
    end
    if params[:q].present? && params[:p].present?
      @project = Project.find(params[:p])
      if @project
        redirect_to :action => 'project', :id => @project
      end
    end

  end

  def dashboard
    @fond = Fond.find(params[:id], :include => [:preferred_event, :creators, :custodians])
    @units_count = @fond.active_descendant_units_count
  end

  def summary
    @fonds = Fond.subtree_of(params[:id]).active.
      all(:include => [:preferred_event], :order => "sequence_number")
    @root_fond_name = @fonds.first.name
  end

  def inventory

    @fond_printable_attributes =
      [
      "fond_type",
      "length",
      "extent",
      "abstract",
      "description",
      "history",
      "arrangement_note",
      "related_materials",
      "access_condition",
      "access_condition_note",
      "use_condition",
      "use_condition_note",
      "type_materials",
      "preservation",
      "preservation_note",
      "description_type",
      "note",
      "units_count"
    ]

    @unit_printable_attributes =
      [
      "tsk",
      "tmp_reference_number",
      "tmp_reference_string",
      "folder_number",
      "file_number",
      "sort_letter",
      "sort_number",
      "unit_type",
      "medium",
      "content",
      "arrangement_note",
      "related_materials",
      "physical_type",
      "physical_description",
      "physical_container_type",
      "physical_container_title",
      "physical_container_number",
      "preservation",
      "preservation_note",
      "restoration",
      "access_condition",
      "access_condition_note",
      "use_condition",
      "use_condition_note",
      "note"
    ]

    @custodian_printable_attributes =
      [
      "headquarter_address",
      "custodian_type.custodian_type",
      "legal_status",
      "owner",
      "contact_person",
      "history",
      "administrative_structure",
      "collecting_policies",
      "holdings",
      "accessibility",
      "services"
    ]

    @creator_printable_attributes =
      [
      "preferred_event.full_display_date",
      "creator_type",
      "creator_corporate_type.corporate_type",
      "residence",
      "abstract",
      "history",
      "legal_status",
      "note"
    ]

    @fonds = Fond.subtree_of(params[:id]).active.
      all(:include => [:preferred_event, :sources, [:units => :preferred_event], [:creators => [:preferred_name, :preferred_event]], [:custodians =>  [:preferred_name, :custodian_headquarter, :custodian_contacts]]],
      :order => "sequence_number")
    @root_fond_name = @fonds.first.name
    @root_fond_id = @fonds.first.id
    @root_fond_preferred_date = @fonds.first.preferred_event.full_display_date if @fonds.first.preferred_event.present?
    respond_to do |format|
      format.html
      format.rtf do
        @builder = RtfBuilder.new
        @builder.target_id = @root_fond_id
        @builder.dest_file = "#{Rails.root}/public/downloads/inventory.rtf"
        @builder.build_fond_rtf_file
        render :json => @builder
        return
      end
    end
  end

  def creators
    fonds =  Fond.subtree_of(params[:id]).active.
      all(:include => [:creators => [:preferred_name, :preferred_event]],
      :order => "sequence_number")

    @root_fond_name = fonds.first.name

    ids = fonds.map(&:id).join(',')

    @creators  =  Creator.all(
      :joins => :rel_creator_fonds,
      :conditions => "rel_creator_fonds.fond_id IN (#{ids})",
      :include => [:preferred_name, :preferred_event]).uniq
  end

  def units
    @root_fond = Fond.find(params[:id], :select => "id, ancestry, name")
    @order = params[:order] || "sequence_number"
    @units  = @root_fond.descendant_units.all(:conditions => "sequence_number IS NOT NULL",
      :include => [:preferred_event], :order => @order)
  end

  def labels
    @root_fond = Fond.find(params[:id], :select => "id, ancestry, name")
    @units = @root_fond.descendant_units.all(:conditions => "sequence_number IS NOT NULL",
      :include => [:fond, :preferred_event])
  end

  def project
    @project_fields =
      [
      "project_type",
      "display_date",
      "description"
    ]

    @fond_fields = [
      "preferred_event.full_display_date",
      "extent",
      "description",
      "abstract",
      "access_condition",
      "access_condition_note",
    ]

    @creator_fields = [
      "preferred_event.full_display_date",
      "history",
      "abstract"
    ]

    @custodian_fields = [
      "history",
      "holdings",
      "collecting_policies",
      "accessibility",
      "services",
      "headquarter_address"
    ]

    @project = Project.find(params[:id], :include => [:project_managers, :project_stakeholders])
    fonds = @project.fonds.roots.active(:include =>
        [:preferred_event, :other_names,
        [:custodians => [:preferred_name, :custodian_headquarter, :custodian_other_buildings, :sources]],
        [:creators => [:preferred_event, :preferred_name, :other_names, :sources]], :sources]
    )
    @custodians = Array.new
    @fonds = Hash.new {|h,k| h[k] = Array.new}
    @creators = Hash.new {|h,k| h[k] = Array.new}
    @sources = Array.new
    fonds.each do |fond|
      fond.sources.each do |source|
        @sources.push(source)
      end
      fond.custodians.each do |custodian|
        custodian.sources.each do |source|
          @sources.push(source)
        end
        @custodians.push(custodian)
        @fonds[custodian.id].push(fond)
        fond.creators.each do |creator|
          @creators[fond.id].push(creator)
          creator.sources.each do |source|
            @sources.push(source)
          end
        end
      end
    end
    @custodians = @custodians.uniq.sort{|a,b| a.display_name <=> b.display_name}
    @sources = @sources.uniq.sort{|a,b| a.short_title <=> b.short_title}
    @fonds.each do |key, value|
      @fonds[key] = value.uniq
    end
    @creators.each do |key, value|
      @creators[key] = value.uniq
    end


    respond_to do |format|
      format.html
      format.rtf do
        @builder = RtfBuilder.new
        @builder.target_id = params[:id]
        @builder.dest_file = "#{Rails.root}/public/downloads/project.rtf"
        @builder.build_project_rtf_file
        render :json => @builder
        return
      end
    end
  end

  def custodian
    @project_fields =
      [
      "project_type",
      "display_date",
      "description"
    ]

    @fond_fields = [
      "preferred_event.full_display_date",
      "extent",
      "description",
      "abstract",
      "access_condition",
      "access_condition_note",
    ]

    @creator_fields = [
      "preferred_event.full_display_date",
      "history",
      "abstract"
    ]

    @custodian_fields = [
      "history",
      "holdings",
      "collecting_policies",
      "accessibility",
      "services",
      "headquarter_address"
    ]

    @custodian= Custodian.find(params[:id], :include => [:preferred_name, :custodian_headquarter, :custodian_other_buildings, :sources])
    fonds = @custodian.fonds.roots.active(:include =>
        [:preferred_event, :other_names,
        [:projects => [:project_managers, :project_stakeholders]],
        [:creators => [:preferred_event, :preferred_name, :other_names, :sources]], :sources]
    )
    @projects= Array.new
    @fonds = Hash.new {|h,k| h[k] = Array.new}
    @creators = Hash.new {|h,k| h[k] = Array.new}
    @sources = Array.new
    fonds.each do |fond|
      fond.sources.each do |source|
        @sources.push(source)
      end
      fond.projects.each do |project|
        @projects.push(project)
        @fonds[project.id].push(fond)
        fond.creators.each do |creator|
          @creators[fond.id].push(creator)
          creator.sources.each do |source|
            @sources.push(source)
          end
        end
      end
    end
    @projects = @projects.uniq
    @sources = @sources.uniq.sort{|a,b| a.short_title <=> b.short_title}
    @fonds.each do |key, value|
      @fonds[key] = value.uniq
    end
    @creators.each do |key, value|
      @creators[key] = value.uniq
    end


    respond_to do |format|
      format.html
      format.rtf do
        @builder = RtfBuilder.new
        @builder.target_id = params[:id]
        @builder.dest_file = "#{Rails.root}/public/downloads/custodian.rtf"
        @builder.build_custodian_rtf_file
        render :json => @builder
        return
      end
    end
  end
end
