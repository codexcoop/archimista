# coding: utf-8

require 'faster_csv'

module TreeExt
  module Debug

    def self.included(klass)
      klass.extend(ClassMethods)
    end

    def units_to_csv(title=nil)
      FileUtils.makedirs "#{Rails.root}/doc/debug_positions"
      file_timestamp = I18n.localize(Time.now, :format => :file_timestamp)
      filename = "#{Rails.root}/doc/debug_positions/units_for_#{id}_#{file_timestamp}"
      filename << "_" << title if title
      filename << ".csv"

      FasterCSV.open(filename, "w") do |csv|
        csv << ['fond_id', 'fond_sequence_number', 'unit_id', 'unit_title', 'unit_ancestry',  'unit_position',
                'memoized_global_position', 'unit_sequence_number', 'check', 'error']
        flat_ordered_external_nodes.each do |unit|
          check = unit.memoized_global_position.to_i - unit.sequence_number.to_i
          csv << [unit.fond_id, unit.fond.sequence_number,
                  unit.id, unit.title[0..70], unit.ancestry, unit.position,
                  unit.memoized_global_position, unit.sequence_number,
                  check, ("ERROR" unless check == 0)]
        end
      end
    end

    def subtree_to_csv(title=nil)
      FileUtils.makedirs "#{Rails.root}/doc/debug_positions"
      file_timestamp = I18n.localize(Time.now, :format => :file_timestamp)
      filename = "#{Rails.root}/doc/debug_positions/subtree_#{id}_#{file_timestamp}"
      filename << "_" << title if title
      filename << ".csv"

      FasterCSV.open(filename, "w") do |csv|
        csv << ['id', 'name', 'ancestry', 'ancestry_depth', 'position', 'memoized_global_position',
                'sequence_number','trashed', 'check', 'error']
        flat_ordered_subtree.each do |node|
          check = node.memoized_global_position.to_i - node.sequence_number.to_i
          csv <<  [ node.id, node.name[0..70], "\""+node.ancestry.to_s+"\"",
                    node.ancestry_depth, node.position, node.memoized_global_position,
                    node.sequence_number, node.trashed, check, ("ERROR" unless check == 0)   ]
        end
      end
    end

    def map_original_params
      flat_ordered_subtree.map do |node|
        {
          :id               => node.id,
          :name             => node.name,
          :ancestry         => node.ancestry,
          :ancestry_depth   => node.ancestry_depth,
          :position         => node.position,
          :global_position  => node.global_position,
          :trashed          => node.trashed
        }
      end
    end

    def map_units_original_params
      Unit.all(:conditions => {:fond_id => subtree_ids}).map do |unit|
        {
          :id               => unit.id,
          :fond_id          => unit.fond_id,
          :root_fond_id     => unit.root_fond_id,
          :title            => unit.title,
          :ancestry         => unit.ancestry,
          :ancestry_depth   => unit.ancestry_depth,
          :position         => unit.position,
          :sequence_number  => unit.sequence_number,
          :trashed          => unit.trashed
        }
      end
    end

    module ClassMethods

      def count_all_units
        Fond.
          roots.
          map{|root| [root.id, Unit.count('id', :conditions => {:fond_id => root.subtree_ids})]}.
          sort_by{|root_id, count| count}
      end

      def restore_original_params
        original_params.each do |params|
          find(params[:id]).update_attributes(params)
        end
      end

      def restore_units_original_params
        unit_original_params.each do |params|
          Unit.find(params[:id]).update_attributes(params)
        end
      end

      def original_params
        []
      end

    end

  end
end

