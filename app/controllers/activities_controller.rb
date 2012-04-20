class ActivitiesController < ApplicationController

  def index
    #@activities = Activity.paginate :page => params[:page], :order => 'id'
  end

  def list
    term = params[:term] || ""
    @activities = Activity.all(:select => "id, activity_en AS value",
    :conditions => "lower(activity_en) LIKE '#{term}%'",
    :order => 'activity_en')

    respond_to do |format|
      format.html
      format.json { render :json => @activities.map(&:attributes) }
    end
  end

end
