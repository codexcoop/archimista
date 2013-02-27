module BulkInsertSupport

  class BulkInsertBuilder

    attr_accessor :model_class,
                  :params,
                  :number_of_records,
                  :position_scope,
                  :sequence_number_scope

    def initialize(model_class, number_of_records, params, bulk_options={})
      @model_class                = model_class
      @number_of_records          = number_of_records.to_i
      @params                     = params.stringify_keys!
      @params['position']         = 0 if bulk_options[:position_scope].present?
      @params['sequence_number']  = 0 if bulk_options[:sequence_number_scope].present?
      @position_scope             = bulk_options[:position_scope]
      @sequence_number_scope      = bulk_options[:sequence_number_scope]
    end

    def conditions_for_scope(scope)
      Hash[*[scope].flatten.map{|field| [field.to_s, params[field.to_s]]}.flatten(1)]
    end

    def conditions_for_position_scope
      return unless position_scope.present?
      conditions_for_scope(position_scope)
    end

    def conditions_for_sequence_number_scope
      return unless sequence_number_scope.present?
      conditions_for_scope(sequence_number_scope)
    end

    def last_position
      return unless position_scope.present?
      @last_position ||= model_class.maximum('position', :conditions => conditions_for_position_scope).to_i
    end

    def last_sequence_number
      return unless position_scope.present?
      @last_sequence_number ||= model_class.maximum('sequence_number', :conditions => conditions_for_sequence_number_scope).to_i
    end

    def start_position
      last_position + 1 if last_position
    end

    def start_sequence_number
      last_sequence_number + 1 if last_sequence_number
    end

    def columns
      columns = (model_class.column_names.map(&:to_s) & params.keys.map(&:to_s)).sort
    end

    def sql_columns
      columns.map do |column_name|
        model_class.connection.instance_eval { quote_column_name(column_name) }
      end.join(', ')
    end

    def statements
      case model_class.connection.adapter_name.downcase
        when 'mysql', 'mysql2'
          ["INSERT INTO #{model_class.quoted_table_name} (#{sql_columns})
            VALUES #{sql_values_bulk}"]
        when 'postgresql'
          ["INSERT INTO #{model_class.quoted_table_name} (#{sql_columns})
            VALUES #{sql_values_bulk}
            RETURNING ID"]
        when 'sqlite'
          sql_values_sets.map do |sql_values_set|
            "INSERT INTO #{model_class.quoted_table_name} (#{sql_columns})
              VALUES #{sql_values_set}"
        end
      end
    end

    def sql_values_sets
      quoted_values_sets.map do |record_values|
        "(#{record_values.join(', ')})"
      end
    end

    def sql_values_bulk
      sql_values_sets.join(', ')
    end

    def values
      columns.map do |column_name|
        case model_class.new.column_for_attribute(column_name.to_s).type
          when :datetime
            params[column_name].to_datetime
          when :integer
            params[column_name].to_i
          when :string, :text
            params[column_name].to_s
          when :boolean
            case params[column_name].to_s
              when 1,'1',true,'true' then true
              when 0,'0',false,'false' then false
            end
        end
      end
    end

    def quoted_values_sets
      values_sets.map do |values_set|
        values_set.map do |value|
          ActiveRecord::Base.instance_eval { quote_value(value) }
        end
      end
    end

    def values_sets
      sets = [values] * number_of_records

      [].tap do |output|
        sets.each_with_index do |values_set, index|
          result = values_set.clone
          if columns.include?('tmp_reference_number')
            result[columns.index('tmp_reference_number')] = if params['tmp_reference_number'].to_i == 0
               nil
            else
              index + params['tmp_reference_number'].to_i
            end
          end
          result[columns.index('sequence_number')] = index + start_sequence_number if columns.include?('sequence_number')
          result[columns.index('position')] = index + start_position if columns.include?('position')
          output << result
        end
      end
    end

  end

end

