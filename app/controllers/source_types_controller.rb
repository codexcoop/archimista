class SourceTypesController < ApplicationController

  def index
    @source_types = SourceType.roots
    # OPTIMIZE: [VERY LOW] si può fare 1 query e presentare albero via Ruby
  end

end
