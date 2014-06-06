
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

    def [](attr)
      @html[attr.to_s]
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
  end

end

