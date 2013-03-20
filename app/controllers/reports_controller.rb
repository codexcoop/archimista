# FIXME: custodian report => report vuoto se manca progetto

# TODO: valutare l'utilizzo di simple_format nelle viste

class ReportsController < ApplicationController

  LIMIT_FOR_PREVIEW = 100

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
    @fonds = Fond.subtree_of(params[:id]).active.all(:include => [:preferred_event], :order => "sequence_number")
    @root_fond_name = @fonds.first.name
    respond_to do |format|
      format.html
      format.pdf do
        filename = pdf_init("summary.html")
        render :json => {:file => "#{filename}.pdf"}
      end
    end
  end

  def inventory

    @fond_printable_attributes = [
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

    @unit_printable_attributes = [
      "preferred_event.full_display_date_with_place",
      "content",
      "physical_description",
      "preservation",
      "preservation_note",
      "reference_number",
      "tmp_reference_number",
      "tmp_reference_string",
    ]
=begin
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
      "use_condition_note"
=end
    @custodian_printable_attributes = [
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

    @creator_printable_attributes = [
      "preferred_event.full_display_date",
      "creator_type",
      "creator_corporate_type.corporate_type",
      "residence",
      "abstract",
      "history",
      "note"
    ]

    @fonds = Fond.subtree_of(params[:id]).active.all(
      :include => [
        :preferred_event, :sources,
        [:units => :preferred_event],
        [:creators => [:preferred_name, :preferred_event, :creator_legal_statuses, :sources]],
        [:custodians =>  [:preferred_name, :custodian_headquarter, :custodian_contacts, :sources]]
      ],
      :order => "sequence_number")

    @root_fond = @fonds.first
    @display_sequence_numbers = Unit.display_sequence_numbers_of(@root_fond)

    respond_to do |format|
      format.html
      format.pdf do
        filename = pdf_init("inventory.html")
        render :json => {:file => "#{filename}.pdf"}
      end
      format.rtf do
        filename = "inventory-#{Time.now.strftime('%Y%m%d%H%M%S')}"
        @builder = RtfBuilder.new
        @builder.target_id = params[:id]
        @builder.dest_file = "#{Rails.root}/public/downloads/#{filename}.rtf"
        @builder.build_fond_rtf_file
        render :json => {:file => "#{filename}.rtf"}
        return
      end
    end
  end

  def creators
    fonds =  Fond.subtree_of(params[:id]).active.all(
      :include => [:creators => [:preferred_name, :preferred_event]],
      :order => "sequence_number")

    @root_fond_name = fonds.first.name

    ids = fonds.map(&:id).join(',')

    @creators  =  Creator.all(
      :joins => :rel_creator_fonds,
      :conditions => "rel_creator_fonds.fond_id IN (#{ids})",
      :include => [:preferred_name, :preferred_event]).uniq
    respond_to do |format|
      format.html
      format.pdf do
        filename = pdf_init("creators.html")
        render :json => {:file => "#{filename}.pdf"}
      end
    end
  end

  def units
    units_list("units.html")
  end

  def labels
    units_list("labels.html")
  end

  def project
    @project_fields = [
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
    fonds = @project.fonds.roots.active.all(:include =>
        [:preferred_event, :other_names,
        [:custodians => [:preferred_name, :custodian_headquarter, :custodian_other_buildings, :sources]],
        [:creators => [:preferred_event, :preferred_name, :other_names, :sources]], :sources]
    )
    @custodians = []
    @fonds = Hash.new {|h,k| h[k] = []}
    @creators = Hash.new {|h,k| h[k] = []}
    @sources = []
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
      format.pdf do
        filename = pdf_init("project.html")
        render :json => {:file => "#{filename}.pdf"}
      end
      format.rtf do
        filename = "project-#{Time.now.strftime('%Y%m%d%H%M%S')}"
        @builder = RtfBuilder.new
        @builder.target_id = params[:id]
        @builder.dest_file = "#{Rails.root}/public/downloads/#{filename}.rtf"
        @builder.build_project_rtf_file
        render :json => {:file => "#{filename}.rtf"}
      end
    end
  end

  def custodian
    @project_fields = [
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

    @custodian = Custodian.find(params[:id], :include => [:preferred_name, :custodian_headquarter, :custodian_other_buildings, :sources])
    fonds = @custodian.fonds.roots.active.all(:include =>
        [:preferred_event, :other_names,
        [:projects => [:project_managers, :project_stakeholders]],
        [:creators => [:preferred_event, :preferred_name, :other_names, :sources]], :sources]
    )
    @projects = []
    @fonds = Hash.new {|h,k| h[k] = []}
    @creators = Hash.new {|h,k| h[k] = []}
    @sources = []
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
      format.pdf do
        filename = pdf_init("custodian.html")
        render :json => {:file => "#{filename}.pdf"}
      end
      format.rtf do
        filename = "custodian-#{Time.now.strftime('%Y%m%d%H%M%S')}"
        @builder = RtfBuilder.new
        @builder.target_id = params[:id]
        @builder.dest_file = "#{Rails.root}/public/downloads/#{filename}.rtf"
        @builder.build_custodian_rtf_file
        render :json => {:file => "#{filename}.rtf"}
      end
    end
  end

  def download
    file = "#{Rails.root}/public/downloads/#{params[:file]}"
    send_file(file)
  end

  private

  def units_list(action)
    @fond = Fond.find(params[:id], :select => "id, ancestry, name")
    @display_sequence_numbers = Unit.display_sequence_numbers_of(@fond.root)
    params[:order] ||= "sequence_number"
    params[:mode] ||= "full"
    params[:subtree] ||= "1"

    options = {
      :conditions => "sequence_number IS NOT NULL",
      :include => [:preferred_event],
      :order => "units.#{params[:order]}"
    }

    if params[:subtree] == "1"
      @subtree_ids = @fond.subtree.active.all(:select => "id").map(&:id)
      options.merge!({:conditions => {:fond_id => @subtree_ids}})
    else
      options.merge!({:conditions => {:fond_id => @fond.id}})
    end

    @units_count = Unit.count(options)

    options.merge!({:limit => LIMIT_FOR_PREVIEW}) if params[:mode] == "preview"

    @units = Unit.all(options)

    filename = "#{File.basename(action,'.*')}-#{Time.now.strftime('%Y%m%d%H%M%S')}"

    respond_to do |format|
      format.html
      format.pdf do
        filename = pdf_init(action)
        render :json => {:file => "#{filename}.pdf"}
      end
      format.csv do
        File.open("#{Rails.root}/public/downloads/#{filename}.csv", 'w') do |f|
          f.write(Unit.to_csv(@units, @fond.root.name, @display_sequence_numbers))
        end
        render :json => {:file => "#{filename}.csv"}
      end
      format.xls do
        File.open("#{Rails.root}/public/downloads/#{filename}.xls", 'w') do |f|
          f.write(render_to_string)
        end
        render :json => {:file => "#{filename}.xls"}
      end

    end
  end

  def pdf_init(action)
    options = {
      :margin_top    => '2.5cm',
      :margin_right  => '2cm',
      :margin_bottom => '2.5cm',
      :margin_left   => '2cm',
      :footer_font_size => 8,
      :footer_spacing => 15,
      :footer_center => "[page] di [toPage]"
    }

    if action == "labels.html"
      options = {
        :margin_top    => '0.25cm',
        :margin_right  => '0cm',
        :margin_bottom => '0cm',
        :margin_left   => '0cm',
      }
    end

    prefix = File.basename(action, '.*')

    unless ["labels", "inventory", "project", "custodian"].include? prefix
      options.merge!({:orientation => 'Landscape', :dpi => '150'})
    else
      options.merge!({:dpi => '300'})
    end

    filename = "#{prefix}-#{Time.now.strftime('%Y%m%d%H%M%S')}"
    html = render_to_string(:action => action)
    kit = PDFKit.new(html, options)
    kit.stylesheets << "#{Rails.root}/public/stylesheets/reports-print.css"
    kit.to_file("#{Rails.root}/public/downloads/#{filename}.pdf")
    filename
  end
end
