# encoding: utf-8

module TreeExt
  module Template

    # Support class: basic tree data-structure.
    class LiveNode
      attr_accessor :children, :level, :attributes
      def initialize(params)
        self.attributes = params.symbolize_keys
        self.level      = attributes.delete(:level)
        self.children   = []
      end

      def root?
        level.zero?
      end
    end # class LiveNode

    # Support class: converts lines of text in a set of related LiveNode's.
    class TreeTemplate
      attr_accessor :template, :markers, :markers_regexp, :level_regexp, :tree_size, :common_params

      def initialize(template, markers, common_params={})
        @template       = template.clone.lines.reject(&:blank?).join
        @markers        = markers.clone
        @markers.delete(:level)
        @markers_regexp = Regexp.new(@markers.values.uniq.map{|marker| "\\#{marker}*"}.join("|"))
        @level_regexp   = Regexp.new("\\#{markers[:level]}*")
        @common_params  = common_params
      end

      def flat_nodes
        template.lines.map{|line| LiveNode.new( params_from_line(line).merge(common_params) ) }
      end

      # recursive
      def live_root_with_tree(nodes=flat_nodes)
        nodes.shift.tap do |current_node|
          self.tree_size        ||= 1
          subtree               = nodes.take_while{|node| node.level > current_node.level}
          current_node.children = subtree.select{|node| node.level == current_node.level+1}
          self.tree_size        += current_node.children.size
          send(__method__, nodes) while nodes.size > 0 # recursive call
        end
      end

      # If tree_template_markers have been configured as:
      # {:level => "#", :name => "#", :fond_type => "@"}
      # given a line such as "### nome del nodo @ tipologia del nodo"
      # this method returns an hash like:
      # {:level => 2, :name => "nome del nodo", :fond_type => "tipologia del nodo"}
      def params_from_line(line)
        line.strip!
        chars           = line.gsub(markers_regexp){|match| match.to_s[0,1]}.each_char.map
        params          = Hash.new{|h,k| h[k]=""}
        params[:level]  = line.match(level_regexp).to_s.size - 1

        chars.inject(nil) do |attribute, char|
          marker    = markers.select{|k,v| v == char}.first # both ruby 1.8 & 1.9, could be smarter
          attribute = marker.first if marker
          params[attribute] << char unless marker && char == marker[1]
          attribute
        end

        params.each{|k,v| v.strip! if v.respond_to?(:strip!)}
      end

      def self.test_template
        template = <<-END
          # Name of the root fond @ complesso
          ## Series 1 @ serie
          ##### Sub-series 1-a @ serie
          ##### Sub-series 1-b @ serie
          ##### Sub-series 1-c @ serie
          ## Series 2 @ serie
          ### Sub-series 2-a @ serie
          ### Sub-series 2-b @ serie
          #### Sub-sub-series 2-b-I @ serie
          ### Sub-series 2-c @ serie
          ## Series 3 @ serie
          ## Series 4 @ serie
        END

        markers = {:level => "#", :name => "#", :fond_type => "@"}

        self.new(template, markers)
      end

      def self.test_well_formed
        tree = self.test_template
        p tree.live_root_with_tree
        p tree.tree_size # => 9
        p tree.flat_nodes.size # => 12
        p tree.template.lines.map.size # => 12
      end

    end # class TreeTemplate

    def test_template
      template = <<-END
        # Name of the root fond @ complesso
        ## Series 1 @ serie
        ### Sub-series 1-a @ serie
        ### Sub-series 1-b @ serie
        ### Sub-series 1-c @ serie
        ## Series 2 @ serie
        ### Sub-series 2-a @ serie
        ### Sub-series 2-b @ serie
        #### Sub-sub-series 2-b-I @ serie
        ### Sub-series 2-c @ serie
        ## Series 3 @ serie
        ## Series 4 @ serie
      END

      markers = {:level => "#", :name => "#", :fond_type => "@"}

      save_a_tree(template, markers)
    end

    # set/get the markers for the class; default level marker "#"
    def tree_template_markers(markers={})
      return @tree_template_markers if markers.blank?
      markers.symbolize_keys!
      @tree_template_markers = markers
      @tree_template_markers[:level] ||= "#"
      @tree_template_markers
    end

    # Creates a new entire tree of the model, starting from a template in text format.
    # The newly created records already have position and sequence_number.
    # A template has the following structure, with level marked by number of #s:
    #
    #   Name of the root fond
    #   # Series 1
    #   ## Sub-series 1-a
    #   ## Sub-series 1-b
    #   ## Sub-series 1-c
    #   # Series 2
    #   ## Sub-series 2-a
    #   ## Sub-series 2-b
    #   ### Sub-sub-series 2-b-I
    #   ## Sub-series 2-c
    #   # Series 3
    #   # Series 4
    #
    # Usage:
    #
    #   class MyModel < ActiveRecord::Base
    #     extend TreeExt::Template # => the model class gains the method ModelClass.save_a_tree(template)
    #     # required configuration: set the markers' map;
    #     # :name is required, :level defaults to '#';
    #     tree_template_markers :level => '#', :name => '#', :fond_type => '@'
    #   end
    def save_a_tree(template, common_params={})
      template_builder = TreeTemplate.new(template, tree_template_markers, common_params={})
      live_root = template_builder.live_root_with_tree
      return false if template_builder.tree_size != template_builder.flat_nodes.size
      transaction do
        create_tree_from_live_root(live_root)
      end
    end

    # Returns false if the root can't be saved or the given template is not well-formed,
    # the root of the new tree saved in db otherwise.
    def save_a_tree_with_sequence(template, common_params={})
      template_builder = TreeTemplate.new(template, tree_template_markers, common_params)
      live_root = template_builder.live_root_with_tree
      return false if template_builder.tree_size != template_builder.flat_nodes.size
      begin
      transaction do
        new_root = create_tree_from_live_root(live_root)
        return false unless new_root
        new_root.rebuild_sequence
        new_root
      end
      rescue
        return false
      end
    end

    private

    # Does the actual job of converting the text template in a simple tree
    # data structure, which in turn is used to set the values and the hierarchical
    # relationships of the new records.
    # Returns the root of the newly created tree.
    def create_tree_from_live_root(live_node, record=nil)
      record =  if live_node.root?
                  self.new(live_node.attributes)
                elsif record
                  record.children.build(live_node.attributes)
                end
      return false unless record
      record.fond_type = record.fond_type.downcase if record.fond_type.present?
      record.save!
      live_node.children.each do |live_child|
        send(__method__, live_child, record) if record && record.valid? # recursive call
      end
      record
    end

  end
end

