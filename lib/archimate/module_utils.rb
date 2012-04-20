module Archimate
  module ModuleUtils

    private

    def override_defaults(options={})
      options.each_pair do |option, value|
        new_value = value.instance_of?(Array) ? [value].flatten : value
        send("#{option}=", new_value)
      end
    end

  end
end

