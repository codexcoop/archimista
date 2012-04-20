class IccdTermsOaOgtd < ActiveRecord::Base

  def ogtd_ogtt
    [ogtd, ogtt].reject(&:blank?).join(" / ")
  end

  alias_attribute :value, :ogtd_ogtt

end
