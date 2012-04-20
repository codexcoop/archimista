module Archimate
  module CoreExt
    module String

      unless method_defined? :no_leading_zeros
        def no_leading_zeros
          gsub(/0*(\d+)/,'\1')
        end
      end

      unless method_defined? :guess_year
        def guess_year
          gsub(/\D/, ' ').split.select {|t| t.to_i > 1000 && t.to_i < Time.now.year}.first
        end
      end

    end
  end
end

