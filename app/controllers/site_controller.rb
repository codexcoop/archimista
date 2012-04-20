class SiteController < ApplicationController

  def dashboard
    @fonds_count = Fond.roots.accessible_by(current_ability, :read).count
    @creators_count = Creator.accessible_by(current_ability, :read).count
    @custodians_count = Custodian.accessible_by(current_ability, :read).count
  end

  def parse_textile
    render :text => RedCloth.new("#{params[:data]}").to_html
  end

end
