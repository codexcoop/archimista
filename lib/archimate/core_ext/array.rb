module Archimate
  module CoreExt
    module Array

      # OPTMIZE: [Luca] spostare in archidate/utilities
      unless method_defined? :to_naturals
        def to_naturals
          flatten.inject([]) do |memo, item|
            memo << (((memo.size > 0 && memo.last.nil?) || item.to_i == 0 || item.blank?) ? nil : item.to_i)
            memo
          end.compact
        end
      end

    end
  end
end

