class VocabulariesController < ApplicationController

  def index
    @vocabularies = Vocabulary.all
  end

end
