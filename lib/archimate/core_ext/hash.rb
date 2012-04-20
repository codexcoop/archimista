module Archimate
  module CoreExt
    module Hash

      unless method_defined? :assert_required_keys
        def assert_required_keys(*keys)
          required_keys = [*keys].flatten
          if (self.keys & required_keys).size < required_keys.size
            raise ArgumentError, "The following options are required: :#{required_keys.join(', :')}."
          end
        end
      end

    end
  end
end

