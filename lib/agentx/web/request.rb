
module AgentX
  module Web

    class Request
      attr_reader :url, :method

      def initialize(session, url, params={})
        @session = session
        @url, @params = url, params
        @headers = session.headers
        @body = {}
      end

      def headers(headers={})
        if @method
          @headers
        else
          headers.each { |k,v| set_header(k, v) }
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

      def put(body={})
        body(body)
        http(:put)
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

      def full_url
        @full_url ||= case
          when url.start_with?('/')
            "#{@session.base_url}#{url}" 
          when url.start_with?('http://', 'https://') 
            url
          else "#{@session.relative_base_url}#{url}"
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

      HEADER_MAP = {
        accept:              'Accept',
        accept_charset:      'Accept-Charset',
        accept_encoding:     'Accept-Encoding',
        accept_language:     'Accept-Language',
        accept_datetime:     'Accept-Datetime',
        authorization:       'Authorization',
        cache_control:       'Cache-Control',
        connection:          'Connection',
        cookie:              'Cookie',
        content_length:      'Content-Length',
        date:                'Date',
        expect:              'Expect',
        from:                'From',
        host:                'Host',
        if_match:            'If-Match',
        if_modified_since:   'If-Modified-Since',
        if_none_match:       'If-None-Match',
        if_range:            'If-Range',
        if_unmodified_since: 'If-Unmodified-Since',
        max_forwards:        'Max-Forwards',
        origin:              'Origin',
        pragma:              'Pragma',
        proxy_authorization: 'Proxy-Authorization',
        range:               'Range',
        referer:             'Referer',
        referrer:            'Referer',
        te:                  'TE',
        user_agent:          'User-Agent',
        upgrade:             'Upgrade',
        via:                 'Via',
        warning:             'Warning'
      }

      def set_header(k, v)
        @headers[HEADER_MAP[k] || k.to_s] = v
      end

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
          set_header(:cookie, cookies)
        end

        response = nil

        if cacheable? && (response = Cache.read(self))
          if response.fresh?
            AgentX.logger.debug("cache fresh")
          else
            AgentX.logger.debug("cache validate")
            response = validate(response)
          end
        end

        unless response
          AgentX.logger.debug("cache miss")
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
          set_header(:if_modified_since, response.headers.last_modified)
        end

        if response.headers.etag
          set_header(:if_none_match, response.headers.etag)
        end

        response_from_easy(response)
      end

      def response_from_easy(response=nil)
        easy = Ethon::Easy.new

        AgentX.logger.info("easy: #{method} #{full_url}")

        easy.http_request(full_url, method, 
          params: params, body: body, headers: headers)

        unless easy.perform == :ok
          raise "Error: #{easy.return_code}"
        end

        r = Response.from_easy(easy, response)

        Cache.write(self, r) if cacheable? && r.cacheable?

        r
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
end

