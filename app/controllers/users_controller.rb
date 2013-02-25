class UsersController < ApplicationController
  load_and_authorize_resource

  def index
    @users = User.accessible_by(current_ability, :manage).
                  all(:order => "group_id, username", :include => :group)
    @active_users = @users.select { |u| u.active? }
    @inactive_users = @users.select { |u| u.active? == false }
  end

  def show
    @user = User.find(params[:id])
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(params[:user])

    if @user.save
      redirect_to(users_url, :notice => t('devise.messages.create_ok'))
    else
      render :action => "new"
    end
  end

  def edit
    @user = User.find(params[:id])
  end

  def update

    @user = User.find(params[:id])

    if @user.update_attributes(params[:user])
      if current_user.is_at_least_admin?
        redirect_to(users_url, :notice => t('devise.messages.save_ok'))
      else
        redirect_to(root_url, :notice => t('devise.messages.save_ok'))
      end
    else
      render :action => "edit"
    end
  end

  def toggle_active
    @user = User.find(params[:id])
    @user.toggle!(:active)

    redirect_to(users_url, :notice => t('devise.messages.save_ok'))
  end

end
