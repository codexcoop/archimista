class CustodianTypesController < ApplicationController

  def index
    @custodian_types = CustodianType.all
  end

end
