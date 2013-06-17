# TODO: Handle nested lists.
class Parser
  attr_accessor :text, :nodes, :parsed

  def initialize(text=nil, nodes = [])
    @text = text
    @nodes = nodes
    @parsed = false
  end

  def parse
    return @nodes if @text.blank? || @parsed

    list = []
    list_type = ""

    @text = @text.strip
    @text = @text.gsub(/\*{1}(.*?)\*{1}/, "\\b \\1\\b0")
    @text = @text.gsub(/\_{1}(.*?)\_{1}/, "\\i \\1\\i0")

    @text.split("\n").each do |line|
      if line =~ /(#+)(.*)/
        list_type = "ordered_list"
        list << line.gsub(/(#+)(.*)/, "\\2").strip
        next
      elsif line =~ /(\*+)(.*)/
        list_type = "unordered_list"
        list << line.gsub(/(\*+)(.*)/, "\\2").strip
        next
      else
        if !list.empty?
          node = ParserNode.new(list_type, list)
          @nodes << node
          list = []
          list_type = ""
        end
        if line.strip.empty?
          node = ParserNode.new('newline', nil)
        else
          node = ParserNode.new('text', line.strip)
        end
        @nodes << node
      end
      next
    end

    if !list.empty?
      node = ParserNode.new(list_type, list)
      @nodes << node
    end

    @parsed = true
    @nodes
  end
end

class ParserNode
  attr_accessor :type, :content

  def initialize(type, content)
    @type = type
    @content = content
  end

end
