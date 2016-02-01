
module AgentX

  class HTML
    def initialize(html)
      if html.kind_of?(String)
        @html = Nokogiri::HTML(html)
      else
        @html = html
      end
    end

    def to_html
      @html.to_html
    end

    def first(selector)
      (e = @html.css(selector).first) && HTML.new(e)
    end

    def all(selector)
      @html.css(selector).map { |e| HTML.new(e) }
    end

    def parent
      HTML.new(@html.parent)
    end

    def children
      @html.children.map { |e| HTML.new(e) }
    end

    def next
      HTML.new(@html.next)
    end

    def previous
      HTML.new(@html.previous)
    end

    def attributes
      h = {}
      @html.attribute_nodes.each { |n| h[n.name] = n.value }
      h
    end

    def [](attr)
      @html[attr.to_s]
    end

    def form_to_hash(opts={})
      h = {}
      all('input').each do |input|
        h[input['name']] = input['value']
      end
      opts.each do |k,v|
        h[k.to_s] = v
      end
      h
    end

    def to_s
      to_html
    end

    def inspect
      to_html
    end

    def to_nokogiri
      @html
    end

    NBSP = Nokogiri::HTML('&nbsp;').text

    def text
      @html.text.gsub(NBSP, ' ')
    end
  end

end

