# TODO: Handle nested lists.
class Parser
  attr_accessor :text, :nodes, :parsed

  def initialize(text=nil, nodes = [])
    @text = text
    @nodes = nodes
    @parsed = false
  end

  def parse
    return @nodes if @text.nil? || @parsed
    @text = @text.gsub(/\*{1}(.*?)\*{1}/, "\\b \\1\\b0")
    @text = @text.gsub(/\_{1}(.*?)\_{1}/, "\\i \\1\\i0")
    list = []
    list_type = ""
    @text.split("\n").each do |line|
      line.next if line.empty?
      if line =~ /(#+)(.*)/
        list_type = "ordered_list"
        list << line.gsub(/(#+)(.*)/, "\\2").strip
        line.next
      elsif line =~ /(\*+)(.*)/
        list_type = "unordered_list"
        list << line.gsub(/(\*+)(.*)/, "\\2").strip
        line.next
      else
        if list.empty?
          node = ParserNode.new('text', line.strip)
          @nodes << node
        else
          node = ParserNode.new(list_type, list)
          @nodes << node
          list = []
          list_type = ""
        end
      end
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
