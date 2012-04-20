module TreeExt

  class OrderOptionsBuilder
    SPECIAL_KEYS = ['class_name', 'table', 'foreign_key', 'use_for_order', 'attr_name', 'direction']

    attr_reader :params
    attr_accessor :model_class

    def initialize(params, model_class)
      self.model_class = model_class
      self.params = params
    end

    # required params structure, for example:
    #
    #     params =
    #       {"commit"=>"Riordina",
    #        "fond_id"=>"10",
    #        "authenticity_token"=>"6NmTBgTLC+Ht/+wxqjsngpdRzxIZX+vCq0lUzaBL0u4=",
    #        "reorder_attributes"=>
    #         [{"preferred"=>"true", "use_for_order"=>"1", "attr_name"=>"start_date_from", "table"=>"unit_events", "direction"=>"desc"},
    #          {"use_for_order"=>"1", "attr_name"=>"title", "direction"=>"desc"},
    #          {"preferred"=>"true", "use_for_order"=>"1", "attr_name"=>"end_date_from", "table"=>"unit_events", "direction"=>"asc"}]}
    #
    # when the attribute doesn't belong to the current model table,
    # the association name must be specified (not the table name)
    #
    # 'class_name', 'table', 'foreign_key', 'use_for_order', 'attr_name', 'direction' are special params, and used only for the building logic
    # all other params will be used as query conditions
    #
    # example output:
    #
    #     options = Unit.build_order_options(params['reorder_attributes'])
    #
    #     { :order => " CASE WHEN unit_events.start_date_from IS NULL THEN 1 ELSE 0 END,
    #                   unit_events.start_date_from DESC,
    #                   CASE WHEN units.title IS NULL THEN 1 ELSE 0 END,
    #                   units.title DESC,
    #                   CASE WHEN unit_events.end_date_from IS NULL THEN 1 ELSE 0 END,
    #                   unit_events.end_date_from",
    #       :joins => "LEFT OUTER JOIN unit_events ON units.id = unit_events.unit_id AND `unit_events`.`preferred` = 1" }
    #
    #     SELECT DISTINCT
    #       units.id,
    #       units.position,
    #       units.ancestry,
    #       units.fond_id
    #     FROM `units`
    #     LEFT OUTER JOIN unit_events
    #       ON units.id = unit_events.unit_id
    #       AND `unit_events`.`preferred` = 1
    #     WHERE ((`units`.`fond_id` IN (142,143,144,145,146,147,141)))
    #     ORDER BY  units.ancestry,
    #               units.fond_id,
    #               CASE WHEN unit_events.start_date_from IS NULL THEN 1 ELSE 0 END,
    #               unit_events.start_date_from DESC,
    #               CASE WHEN units.title IS NULL THEN 1 ELSE 0 END,
    #               units.title DESC,
    #               CASE WHEN unit_events.end_date_from IS NULL THEN 1 ELSE 0 END,
    #               unit_events.end_date_from
    #
    # Background:
    #
    # Conditions must be in a subselect, or inside the join conditions themselves.
    # The second option, although less intuitive, is easier to implement as a dynamic query.
    # Take the following example, where a User has_many projects through user_projects.
    # If the users records are actually referenced in user_projects, but not with the given condition,
    # they will not appear at all in the results.
    #
    # SELECT *
    # FROM users
    # LEFT OUTER JOIN user_projects
    # ON user_projects.user_id = users.id
    # WHERE user_projects.project_id = 3
    # ;
    #
    # SELECT *
    # FROM users
    # LEFT OUTER JOIN user_projects
    # ON user_projects.user_id = users.id
    # WHERE ( user_projects.project_id = 3 OR user_projects.project_id IS NULL )
    # ;
    #
    # SELECT *
    # FROM users
    # LEFT OUTER JOIN user_projects
    # ON user_projects.user_id = users.id
    # WHERE ( user_projects.project_id = 3 OR user_projects.user_id IS NULL )
    # ;
    #
    # This would work only if the user records whose user_project doesn't match
    # the condition, were not referenced at all in user_records.
    # All these queries don't return the expected result, but the following instead:
    #
    # +----+------+-------+------+---------+------------+
    # | id | name | email | id   | user_id | project_id |
    # +----+------+-------+------+---------+------------+
    # |  3 | Mike |       |    6 |       3 |          3 |
    # |  4 | Dan  |       |    8 |       4 |          3 |
    # +----+------+-------+------+---------+------------+
    #
    # Instead, if we put the conditions in the left outer join option...
    #
    # SELECT *
    # FROM users
    # LEFT OUTER JOIN user_projects
    # ON user_projects.user_id = users.id AND user_projects.project_id = 3
    # ;
    #
    # ...or inside a sub-select (a more classical solution)...
    #
    # SELECT *
    # FROM users
    # LEFT OUTER JOIN
    #   (SELECT * FROM user_projects WHERE project_id = 3) AS membership
    # ON membership.user_id = users.id
    # ;
    #
    # we actually have all the records we want, and can sort them.
    #
    # +----+------+-------+------+---------+------------+
    # | id | name | email | id   | user_id | project_id |
    # +----+------+-------+------+---------+------------+
    # |  1 | John |       | NULL |    NULL |       NULL |
    # |  2 | Jack |       | NULL |    NULL |       NULL |
    # |  3 | Mike |       |    6 |       3 |          3 |
    # |  4 | Dan  |       |    8 |       4 |          3 |
    # +----+------+-------+------+---------+------------+
    #
    def build_order_options
      return if params.empty?
      params.each { |field_params| add_field_options(field_params) }
      finalize_order_options
    end

    def order_options
      @order_options ||=  { :joins => [], :order => [], :conditions => [] }
    end

    private

    def params=(params)
      normalize_params(params)
    end

    def normalize_params(params)
      @params = params.clone
      clone_single_fields_params
      filter_params_to_use_for_order
      set_defaults_for_fields_params
    end

    def clone_single_fields_params
      @params.each_with_index { |param, index| @params[index] = param.clone }
    end

    def filter_params_to_use_for_order
      @params.delete_if do |field_params|
        [1, '1', true, 'true', 'on'].index(field_params['use_for_order']).nil?
      end
    end

    def set_defaults_for_fields_params
      @params.each do |field_params|
        field_params['table'] = get_order_table_from_params(field_params)
        field_params['foreign_key'] ||= model_class.name.foreign_key
      end
    end

    def get_order_table_from_params(field_params)
      field_params['table'] ||
      ( field_params['class_name'] && field_params['class_name'].to_s.constantize.table_name ) ||
      model_class.table_name
    end

    def normalized_param_value(value)
      if value.to_i.to_s == value
        value.to_i
      elsif ['true', 't'].include? value.to_s.downcase
        true
      elsif ['false', 'f'].include? value.to_s.downcase
        false
      else
        value
      end
    end

    def filter_special_keys_from_params(field_params)
      field_params.clone.delete_if { |k, v| SPECIAL_KEYS.include? k }
    end

    # returns an array as [:unit_events, :preferred, true] where [0] is the order table, [1] the field, and [2] the value
    def normalized_fields_conditions(field_params)
      filter_special_keys_from_params(field_params).map do |field, value|
        [ field_params['table'].to_sym, field.to_sym, normalized_param_value(value) ]
      end
    end

    def single_field_condition(order_table, field, value)
      { order_table => { field => value } }
    end

    def single_field_sql_condition(order_table, field, value)
      model_class.send( :sanitize_sql_hash, single_field_condition(order_table, field, value) )
    end

    def update_order_conditions_with(field_params)
      return if field_params.blank?
      normalized_fields_conditions(field_params).each do |order_table, field, value|
        field_condition = single_field_condition(order_table, field, value)
        if order_table.to_s != model_class.table_name
          field_condition = model_class.merge_conditions(field_condition) + " OR #{order_table}.#{field} IS NULL"
        end
        order_options[:conditions] << field_condition unless order_options[:conditions].include?(field_condition)
      end
    end

    def update_order_joins_with(field_params)
      order_table = field_params['table']
      foreign_key = field_params['foreign_key']

      return if order_table == model_class.table_name

      order_join = "LEFT OUTER JOIN #{order_table} ON #{model_class.table_name}.#{model_class.primary_key} = #{order_table}.#{foreign_key}"

      normalized_fields_conditions(field_params).each do |order_table, field, value|
        order_join << " AND #{single_field_sql_condition(order_table, field, value)}"
      end

      order_options[:joins] << order_join unless order_options[:joins].include?(order_join)
    end

    def update_order_fields_with(field_params)
      order_table = field_params['table']
      attr_name   = field_params['attr_name']
      direction   = field_params['direction'].to_s.upcase

      return if order_options[:order].assoc("#{order_table}.#{attr_name}")

      # ensure NULLs last
      order_options[:order] << ["CASE WHEN #{order_table}.#{attr_name} IS NULL THEN 1 ELSE 0 END"]
      order_options[:order] << ["#{order_table}.#{attr_name}"]
      order_options[:order].last << "#{direction}" if direction == 'DESC'
    end

    def add_field_options(field_params)
      update_order_joins_with( field_params )
      update_order_fields_with( field_params )
    end

    def finalize_order_options
      order_options[:joins] = order_options[:joins].join(' ')
      order_options[:order] = order_options[:order].map{ |opt| opt.join(' ') }.join(', ')
      if order_options[:conditions].empty?
        order_options.delete(:conditions)
      else
        order_options[:conditions] = model_class.merge_conditions(*order_options[:conditions])
      end
      order_options
    end

  end # class OrderOptionsBuilder

end # module TreeExt

