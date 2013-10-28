# encoding: utf-8

require 'unit_support/bulk_insert_support'

module UnitSupport

  module ClassMethods

    include BulkInsertSupport

    # Arrange given terms in a hash of ordered hashes, ready to be converted to json,
    # and sent to the grid plugin, where the vocabularies can be accessed as in vocabularies['units.unit_type'].
    def vocabularies_for_grid(terms)
      vocabularies = terms.map{|term|term.attributes}.group_by{|attrs| attrs['vocabulary_name']}
      vocabularies.each do |vocabulary, terms_attrs|
        options = ['',''] + terms_attrs.map{|term_attr| [term_attr['term_value'], term_attr['term_value']] }
        options = ActiveSupport::OrderedHash[*options.flatten]
        vocabularies[vocabulary] = options
      end
      vocabularies['units.ancestry_depth'] = ActiveSupport::OrderedHash['','','0',"solo unità"]
      vocabularies
    end

    # Returns a paginated collection of records (units), given an ancestor (fond).
    # Required arguments:
    # - fond
    # - params: all the data useful to find the desired record;
    #   - params[:sord] ASC or DESC
    #   - params[:sidx] is the sql column of the main table, by which the records will be ordered;
    #     the name of the table should not be included, for jqgrid compatibility;
    #     special cases are: 'fond_name' will be converted to "fonds.name",
    #     and 'preferred_event' converted to "unit_events.order_date";
    #     all the others will be converted to "#{quoted_table_name}.#{params[:sidx]}"
    #
    def units_for_grid(fond, params, selected_attributes)
      if fond.is_root?
        fond.descendant_units
      else
        fond.units
      end.
        paginate( :page => params[:page],
                  :per_page => (params[:rows] || Unit.per_page),
                  :select => select_for_grid(selected_attributes),
                  :joins => joins_for_grid,
                  :conditions => conditions_for_grid(params),
                  :order => order_sql_for_grid(params) )
    end

    def jqgrid_rows(units, selected_attributes, display_sequence_numbers)
      units.map do |unit|
        {
          :id => unit.id,
          :cell => selected_attributes.map do |attribute|
            case attribute.to_s
            when 'sequence_number'
              unit.display_sequence_number_from_hash(display_sequence_numbers)
            when 'preferred_event'
              [unit.preferred_start_date_display, unit.preferred_end_date_display].uniq.join(" - ")
            else
              unit.send(attribute)
            end
          end
        }
      end
    end

    def bulk_insert_builder(number_of_records, params, bulk_options={})
      BulkInsertBuilder.new(self, number_of_records, params, bulk_options)
    end

    # TODO: [Luca] questo e metodi seguenti => rendere dignitosi
    def bulk_create(number_of_records, params, opts={})
      return if number_of_records.to_i < 1 || self.new(params).invalid?

      first_inserted  = nil

      transaction do
        bulk_insert_builder(number_of_records, params, opts).statements.each do |statement|
          connection.execute(statement)
        end
        # NOTE: NON THREAD-SAFE, per renderlo thread-safe, gestire il last come variabile di istanza dell'oggetto BulkInsertBuilder
        result              = connection.execute(last_insert_id_sql)
        first_inserted      = find(first_inserted_id(result, number_of_records))
        result.free if connection.adapter_name.downcase.match(/mysql/)
        new_units_count     = Unit.count('id', :conditions => {:fond_id => params[:fond_id]})
        # TODO: [Luca] spostare in un metodo
        Fond.update_all({:units_count => new_units_count}, {:id => params[:fond_id]})
        first_inserted.update_sequence if first_inserted.respond_to? :update_sequence
        first_inserted.update_sequence_for_structural_root if first_inserted.respond_to? :update_sequence_for_structural_root
      end

      first_inserted
    end

    def bulk_delete(ids)
      return false if ids.blank?

      transaction do
        unit_ids = ids.map{|id| find(id).subtree_ids}.flatten.uniq
        fond_ids =  find(:all, :select => "DISTINCT fond_id", :conditions => {:id => unit_ids}).
                    map{|u|u.fond_id} # warning: must be found *before* deletion
        UnitEvent.delete_all({:unit_id => unit_ids})
        DigitalObject.delete_all({:attachable_type => 'Unit', :attachable_id => unit_ids})
        delete_all({:id => unit_ids})
        bulk_update_fonds_units_count(fond_ids) # warning: must be updated *after* deletion
        unit_ids.size
      end
    end

    def bulk_update_fonds_units_count(fond_ids)
      Fond.transaction { Fond.connection.execute bulk_update_fonds_units_count_sql(fond_ids) }
    end

    private

    def bulk_update_fonds_units_count_sql(fond_ids)
      case Fond.connection.adapter_name.downcase
        when 'mysql', 'mysql2'
          "UPDATE
              fonds,
              ( SELECT f1.id AS fond_id, COUNT(units.id) AS units_count
                FROM fonds AS f1 LEFT OUTER JOIN units ON f1.id = units.fond_id
                WHERE f1.id IN (#{fond_ids.join(',')})
                GROUP BY f1.id ) AS units_count
            SET fonds.units_count = units_count.units_count
            WHERE fonds.id = units_count.fond_id;".squish
        when 'postgresql', 'sqlite'
          "UPDATE fonds
          SET units_count = ( SELECT COUNT(units.id) AS count
                              FROM units
                              WHERE fonds.id = units.fond_id )
          WHERE fonds.id IN (#{fond_ids.join(',')});".squish
      end
    end

    def select_for_grid(selected_attributes)
      selected_attributes.map do |attribute|
        column = self.new.column_for_attribute(attribute.to_s)
        if attribute == 'fond_name'
          "fonds.name AS fond_name"
        elsif attribute == 'preferred_event'
          "unit_events.start_date_display  AS preferred_start_date_display,
           unit_events.end_date_display    AS preferred_end_date_display,
           unit_events.order_date          AS preferred_order_date".squish
        elsif column.nil?
          next
        else
          "#{table_name}.#{column.name}"
        end
      end.compact.join(", ")
    end

    def order_sql_for_grid(params)
      if params[:sidx].blank?
        "#{quoted_table_name}.sequence_number"
      else
        case params[:sidx]
          when 'fond_name' then "fonds.name #{params[:sord]}"
          when 'preferred_event' then "unit_events.order_date #{params[:sord]}"
          else "#{quoted_table_name}.#{params[:sidx]} #{params[:sord]}"
        end
      end
    end

    def last_insert_id_sql
      case connection.adapter_name.downcase
      when 'mysql', 'mysql2' then %Q{SELECT LAST_INSERT_ID() AS `id`}
      when 'sqlite' then %Q{SELECT LAST_INSERT_ROWID() AS "id"}
      when 'postgresql' then %Q{SELECT currval('units_id_seq') AS "id"}
      end
    end

    def first_inserted_id(result, number_of_records)
      case connection.adapter_name.downcase
        when 'mysql', 'mysql2' then result.fetch_hash['id']
        when 'sqlite', 'postgresql' then result.first['id'].to_i - number_of_records.to_i + 1
      end
    end

    # Grid search support

    def columns_of_type(*types)
      columns.select do |column|
        types.map(&:to_s).include?(column.instance_variable_get(:'@type').to_s) &&
        columns_to_search.include?(column.name)
      end
    end

    def conditions_for_strings(params)
      columns_of_type(:string).map do |column|
        if params[column.name.to_s].present?
          ["LOWER(#{quoted_table_name}.#{column.name}) LIKE ?", "%#{params[column.name.to_s].squish.downcase}%"]
        end
      end.compact
    end

    def conditions_for_texts(params)
      columns_of_type(:text).map do |column|
        if params[column.name.to_s].present?
          ["LOWER(#{quoted_table_name}.#{column.name}) LIKE ?", "%#{params[column.name.to_s].squish.downcase}%"]
        end
      end.compact
    end

    def conditions_for_integers(params)
      columns_of_type(:integer).map do |column|
        if params[column.name.to_s].present?
          ["#{quoted_table_name}.#{column.name} = ?", params[column.name.to_s].to_i]
        end
      end.compact
    end

    def conditions_for_booleans(params)
      columns_of_type(:boolean).map do |column|
        if params[column.name.to_s].present?
          case params[column.name.to_s]
          when 1,'1',true,'true','t' then ["#{quoted_table_name}.#{column.name} = ?", true]
          when 0,'0',false,'false','f' then ["#{quoted_table_name}.#{column.name} = ?", false]
          else nil
          end
        end
      end.compact
    end

    def condition_for_fond_name(params)
      return if params['fond_name'].blank?
      [[ "fonds.name LIKE ?", "%#{params['fond_name'].squish.downcase}%"]]
    end

    def conditions_for_grid(params)
      merge_conditions(
        {:fonds => {:trashed => false}},
        ["unit_events.preferred = ? OR unit_events.preferred IS NULL", true],
        *[
          condition_for_fond_name(params),
          conditions_for_strings(params),
          conditions_for_texts(params),
          conditions_for_integers(params),
          conditions_for_booleans(params)
        ].flatten(1).compact
      )
    end

  end
end