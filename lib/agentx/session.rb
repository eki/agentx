
module AgentX

  class Session
    attr_reader :history, :cookies

    def initialize
      @history = History.new
      @cookies = CookieJar.new
    end

    def [](url, params={})
      Request.new(self, url, params)   
    end

    def inspect
      "(Session)"
    end

  end

end
