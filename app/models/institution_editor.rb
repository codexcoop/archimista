class InstitutionEditor < ActiveRecord::Base
  belongs_to :institution
  belongs_to :editor
end

