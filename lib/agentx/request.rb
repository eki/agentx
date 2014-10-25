
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

    def head(params={})
      params(params)
      http(:head)
    end

    def get(params={})
      params(params)
      http(:get)
    end

    def post(body={})
      body(body)
      http(:post)
    end

    def cacheable?
      method == 'GET' || method == 'HEAD'
    end

    # Force: parse response as json (normally type is determined by correctly
    # set headers.

    def json
      @json = true

      self
    end

    def json?
      @json
    end

    def inspect
      if @method
        "(Request #{@method.to_s.upcase} #{url})"
      else
        "(Request #{url})"
      end
    end

    def full_url
      url.start_with?('/') ? "#{@session.base_url}#{url}" : url
    end

    def to_hash
      { 'url'     => full_url, 
        'method'  => method,
        'body'    => body, 
        'headers' => headers,
        'params'  => params }
    end

    def cache_key
      k = [full_url, method, body, params]
      Digest::MD5.hexdigest(Oj.dump(k, mode: :compat))
    end

    private

    def http(verb, params=@params, body=@body, headers=@headers)
      @method = verb.to_s.upcase

      if cookies = HTTP::Cookie.cookie_value(@session.jar.cookies(full_url))
        headers.merge!('Cookie' => cookies)
      end

      response = nil

      if cacheable? && (response = Cache.read(self))
        if response.fresh?
          puts "cache fresh"
        else
          puts "cache validate"
          response = validate(response)
        end
      end

      unless response
        puts "cache miss"
        easy = Ethon::Easy.new
        easy.http_request(full_url, method, 
          params: params, body: body, headers: headers)
        unless easy.perform == :ok
          raise "Error: #{easy.return_code}"
        end
        response = Response.from_easy(easy)
        Cache.write(self, response) if cacheable? && response.cacheable?
      end

      @session.history.add(self, response)
      response.cookies.each do |cookie|
        @session.jar.parse(cookie, full_url)
      end

      if response.headers.location
        @session[response.headers.location].get
      else
        response.parse(json? ? :json : nil)
      end
    end

    def validate(response)
      if response.headers.last_modified
        puts "add last_modified"
        @headers['If-Modified-Since'] = response.headers.last_modified
      end

      if response.headers.etag
        puts "add etag"
        @headers['If-None-Match'] = response.headers.etag
      end

      puts "added headers: #{headers}"

      easy = Ethon::Easy.new
      easy.http_request(full_url, method, 
        params: params, body: body, headers: headers)
      unless easy.perform == :ok
        raise "Error: #{easy.return_code}"
      end
      response = Response.from_easy(easy, response)

      Cache.write(self, response) if cacheable? && response.cacheable?

      response
    end
  end

end

