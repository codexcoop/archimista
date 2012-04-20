module TreeExt
  module ActsAsSequence
    module Utils

      private

      def break_groups_by_key(array, opts={})
        # TODO: [Luca] aggiungere gestione eccezioni
        #assert_valid_keys     :key, :attr, :seed
        #assert_required_keys  :key, :attr

        return self if array.empty?

        seed        = opts[:seed]
        key_attr    = opts[:key].to_sym
        group_attr  = opts[:attr].to_sym

        groups = []

        # seed the groups
        if seed || array.size == 1
          groups << [array.first.send(key_attr), array.first.send(group_attr)]
        end

        # create the groups
        array.each_cons(2) do |a,b|
          if b.send(key_attr) != a.send(key_attr)
            groups << [b.send(key_attr), b.send(group_attr)]
          else
            groups.last << b.send(group_attr)
          end
        end

        groups
      end

      def nest_groups_by_key(array, seeds=nil)
        # seed the list
        list = seeds || [array.first.first]
        # rearrange groups in the list
        array.each do |key, *values|
          insert_position = list.index(key)+1
          list.insert(insert_position, values)
          list.flatten!
        end
        list
      end

      def sort_by_list(array, list, opts={}, &block)
        key = opts[:key].to_sym

        array.each do |element|
          list_index = list.index(element.send(key))
          if list_index
            block.call(element, list_index) if block_given?
            list[list_index] = element
          end
        end

        array.replace(list)
      end

      # Used in fast_subtree_to_jstree_hash
      def find_in_nested_list(list, ids)
        last_id = ids.pop

        element_before_last = ids.inject(list) do |restricted_list, current_id|
          restricted_list.find{|el| el[:id] == current_id}[:children]
        end

        element_before_last.find{|el| el[:id] == last_id}
      end

    end
  end
end

