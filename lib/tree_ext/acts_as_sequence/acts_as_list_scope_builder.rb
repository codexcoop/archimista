module TreeExt
  module ActsAsSequence
    module ActsAsListScopeBuilder

      attr_accessor :list_scope_fields, :list_scope

      # This list of fields, is useful particularly when you have to set a different position:
      # this ay you know that the new positions that you are determining must be scoped
      # on these fields.
      # The order of the fields is irrelevant.
      def list_scope_fields(*field_names)
        return @list_scope_fields if field_names.empty?
        @list_scope_fields = field_names
      end

      # deferred evaluation to support acts_as_list
      # example: list_scope_fields => :ancestry, :fond_id, ancestry = NULL and fond_id = 123
      # => ancestry IS NULL AND fond_id = 123
      def list_scope
        @list_scope ||= list_scope_fields.map do |field_name|
          case Unit.columns.find{|c| c.name.to_s == field_name.to_s}.type
          when :integer, :float, :decimal
            %Q[ #{field_name} \#{ #{field_name}.nil? ? " IS NULL" : (" = \#{#{field_name}}") } ]
          when :string, :text
            %Q[ #{field_name} \#{ #{field_name}.nil? ? " IS NULL" : (" = '\#{#{field_name}}'") } ]
          end
        end.join(' AND ')
      end

    end
  end
end

