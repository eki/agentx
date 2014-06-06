
module AgentX

  class Request
    attr_reader :url, :method

    def initialize(session, url, params={})
      @session = session
      @url, @params = url, params
      @headers = {}
      @body = {}
    end

    def headers(headers=nil)
      if @method
        @headers
      else
        @headers.merge!(headers) if headers
        self
      end
    end

    def body(body=nil)
      if @method
        @body
      else
        @body.merge!(body) if body
        self
      end
    end

    def params(params=nil)
      if @method
        @params
      else
        @params.merge!(params) if params
        self
      end
    end

    def get(params={})
      params(params)
      http(:get)
    end

    def post(body={})
      body(body)
      http(:post)
    end

    def inspect
      if @method
        "(Request #{@method.to_s.upcase} #{url})"
      else
        "(Request #{url})"
      end
    end

    private

    def cookies
      # TODO:  select only cookies that are relevant to this request
      unless @session.cookies.all.empty?
        @session.cookies.all.map { |c| c.to_s }.join('; ')
      end
    end

    def http(verb, params=@params, body=@body, headers=@headers)
      @method = verb

      headers.merge!('Cookie' => cookies) if cookies

      easy = Ethon::Easy.new
      easy.http_request(url, verb, 
        params: params, body: body, headers: headers)
      easy.perform
      response = Response.from_easy(easy)
      @session.history.add(self, response)
      response.cookies.each do |cookie|
        @session.cookies.store(cookie)
      end
      response.parse
    end
  end

end

