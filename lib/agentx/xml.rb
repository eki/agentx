
module AgentX

  class XML
    def initialize(xml)
      if xml.kind_of?(String)
        @xml = Nokogiri::XML(xml)
      else
        @xml = xml
      end
    end

    def to_xml
      @xml.to_xml
    end

    def first(selector)
      (e = @xml.css(selector).first) && XML.new(e)
    end

    def all(selector)
      @xml.css(selector).map { |e| XML.new(e) }
    end

    def parent
      XML.new(@xml.parent)
    end

    def children
      @xml.children.map { |e| XML.new(e) }
    end

    def next
      XML.new(@xml.next)
    end

    def previous
      XML.new(@xml.previous)
    end

    def attributes
      h = {}
      @xml.attribute_nodes.each { |n| h[n.name] = n.value }
      h
    end

    def [](attr)
      @xml[attr.to_s]
    end

    def to_s
      to_xml
    end

    def inspect
      to_xml
    end

    def to_nokogiri
      @xml
    end
  end

end

