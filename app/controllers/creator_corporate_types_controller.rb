class CreatorCorporateTypesController < ApplicationController

  def index
    @creator_corporate_types = CreatorCorporateType.all
  end

end
