
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
      @parse_type = :json

      self
    end

    def json?
      @parse_type == :json
    end

    def html
      @parse_type = :html

      self
    end

    def html?
      @parse_type == :html
    end

    def xml
      @parse_type = :xml

      self
    end

    def xml?
      @parse_type == :xml
    end

    def inspect
      if @method
        "(Request #{@method.to_s.upcase} #{url})"
      else
        "(Request #{url})"
      end
    end

    def host
      uri.host
    end

    def scheme
      uri.scheme
    end

    def port
      uri.port
    end

    def base_url
      return @session.base_url if @session.base_url

      if uri.port != AgentX::Session::DEFAULT_PORT[uri.scheme]
        "#{uri.scheme}://#{uri.host}:#{uri.port}"
      else
        "#{uri.scheme}://#{uri.host}"
      end
    end

    def cache_key
      k = [full_url, method, body, params]
      Digest::MD5.hexdigest(Oj.dump(k, mode: :compat))
    end

    def timings
      ts = {}
      (@times || {}).each do |k,v|
        ts[k] = "#{'%.2f' % (v * 1000)}ms"
      end
      ts
    end

    def request_time
      timings[:http_request]
    end

    private

    def http(*args)
      r = nil
      time(:http_request) do
        r = untimed_http(*args)
      end
      AgentX.logger.info([
        request_time, 
        @session.history.last.response.code,
        method, 
        full_url].join(' '))
      r
    end

    def untimed_http(verb, params=@params, body=@body, headers=@headers)
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
        response = response_from_easy
      end

      @session.history.add(self, response)
      response.cookies.each do |cookie|
        @session.jar.parse(cookie, full_url)
      end

      if response.headers.location
        @session[response.headers.location].get
      else
        response.parse(@parse_type)
      end
    end

    def validate(response)
      if response.headers.last_modified
        @headers['If-Modified-Since'] = response.headers.last_modified
      end

      if response.headers.etag
        @headers['If-None-Match'] = response.headers.etag
      end

      response_from_easy(response)
    end

    def response_from_easy(response=nil)
      easy = Ethon::Easy.new

      easy.http_request(full_url, method, 
        params: params, body: body, headers: headers)

      unless easy.perform == :ok
        raise "Error: #{easy.return_code}"
      end

      r = Response.from_easy(easy, response)

      Cache.write(self, r) if cacheable? && r.cacheable?

      r
    end

    def full_url
      url.start_with?('/') ? "#{@session.base_url}#{url}" : url
    end

    def uri
      @uri ||= URI(full_url)
    end

    def time(name)
      @times ||= {}
      start = Time.now
      r = yield
      @times[name] = Time.now - start
      r
    end

  end
end

