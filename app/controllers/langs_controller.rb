class LangsController < ApplicationController

  def index
    @langs = Lang.paginate(:page => params[:page], :order => "active DESC, code ASC")
  end

  def show
    @lang = Lang.find(params[:id])
  end

  def new
    @lang = Lang.new
  end

  def edit
    @lang = Lang.find(params[:id])
  end

  def create
    @lang = Lang.new(params[:lang])

    if @lang.save
      redirect_to(@lang, :notice => 'Scheda creata')
    else
      render :action => "new"
    end
  end

  def update
    @lang = Lang.find(params[:id])

    if @lang.update_attributes(params[:lang])
      redirect_to(@lang, :notice => 'Scheda aggiornata')
    else
      render :action => "edit"
    end
  end

  def destroy
    @lang = Lang.find(params[:id])
    @lang.destroy

    redirect_to(langs_url)
  end

end
