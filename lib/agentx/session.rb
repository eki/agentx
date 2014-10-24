
module AgentX

  class Session
    attr_reader :history, :jar

    def initialize(base_url=nil, opts={})
      @history = History.new
      path = File.join(AgentX.root, opts[:cookie_store] || 'cookies.sqlite')
      @jar = HTTP::CookieJar.new(store: :mozilla, filename: path)
      @base_url = base_url
    end

    DEFAULT_PORT = { 'http' => 80, 'https' => 443 }

    def base_url
      if url = URI(@base_url || (history.last && history.last.request.url))
        if url.port != DEFAULT_PORT[url.scheme]
          "#{url.scheme}://#{url.host}:#{url.port}"
        else
          "#{url.scheme}://#{url.host}"
        end
      end
    end

    def [](url, params={})
      Request.new(self, url, params)   
    end

    def inspect
      "(Session)"
    end

  end

end

