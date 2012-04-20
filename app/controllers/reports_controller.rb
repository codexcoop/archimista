class ReportsController < ApplicationController

  def index
    @fonds = Fond.list.
      roots.
      accessible_by(current_ability, :read).
      active.
      default_order

    case @fonds.size
    when 1
      redirect_to :action => 'dashboard', :id => @fonds[0]
    else
      if params[:q].present? && params[:f].present?
        @fond = Fond.find(params[:f])
        if @fond
          redirect_to :action => 'dashboard', :id => @fond
        end
      end
    end
  end

  def dashboard
    @fond = Fond.find(params[:id], :include => [:creators, :custodians])

    @units_count = Unit.count(
      "id",
      :joins => :fond,
      :conditions => {:root_fond_id => @fond, :fonds => {:trashed => false}},
      :group => :root_fond_id
    )

  end

  def summary

    @fonds = Fond.subtree_of(params[:id]).active.
      all(:include => [:preferred_event],
      :order => "sequence_number")
    @root_fond_name = @fonds.first.name

  end

  def inventory
    @fonds = Fond.subtree_of(params[:id]).active.
      all(:include => [:preferred_event, [:units => :preferred_event], [:creators => [:preferred_name, :preferred_event]]],
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
        @builder.build_rtf_file
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
      :include => [:preferred_name, :preferred_event])
  end

  def custodians
    fonds = Fond.subtree_of(params[:id]).active.
      all(:include => [:custodians => [:preferred_name, :custodian_buildings]],
      :order => "sequence_number")

    @root_fond_name = fonds.first.name

    ids = fonds.map(&:id).join(',')

    @custodians = Custodian.all(
      :joins => :rel_custodian_fonds,
      :conditions => "rel_custodian_fonds.fond_id IN (#{ids})",
      :include => [:preferred_name, :custodian_headquarter])

    @custodians.uniq.sort! { |a,b| a['name'].downcase <=> b['name'].downcase }
  end

  def labels
    @fond   = Fond.find(params[:id], :select => "id, ancestry, name")
    @units  = @fond.descendant_units.all(:include => [:preferred_event])

    @root_fond_name = @fond.name

  end

  def units_by_reference_number
    @fond   = Fond.find(params[:id], :select => "id, ancestry, name")
    @units  = @fond.descendant_units.all(:include => [:preferred_event], :order => "folder_number, file_number, sort_letter, reference_number")
    @root_fond_name = @fond.name
  end

  def units_by_sequence_number
    @fond   = Fond.find(params[:id], :select => "id, ancestry, name")
    @units  = @fond.descendant_units.all(:include => [:preferred_event], :order => [:sequence_number])
    @root_fond_name = @fond.name
  end

end
