module Archimate
  module CoreExt
    module Object

      def is_in?(*array)
        array = array.flatten
        raise ArgumentError unless array.is_a?(Array) && array.respond_to?(:include?)
        array.include?(self)
      end

      def not_in?(array)
        !is_in?(*array)
      end

    end
  end
end

