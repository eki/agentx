
module AgentX

  class Session
    attr_reader :history, :jar

    def initialize
      @history = History.new
      @jar = HTTP::CookieJar.new
    end

    def [](url, params={})
      Request.new(self, url, params)   
    end

    def inspect
      "(Session)"
    end

  end

end

