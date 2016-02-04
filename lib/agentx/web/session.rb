
module AgentX
  module Web

    class Session
      attr_reader :history, :jar

      def initialize(base_url=nil, opts={})
        @history = History.new
        path = File.join(AgentX.root, opts[:cookie_store] || 'cookies.sqlite')
        @jar = HTTP::CookieJar.new(store: :mozilla, filename: path)
        @base_url = base_url
        @headers = {}
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

      def relative_base_url
        if history.last
          uri = URI(history.last.request.full_url)
          path = uri.path.split('/')
          path.pop

          URI.join(uri, path.empty? ? '/' : path.join)
        else
          base_url
        end
      end

      def headers(headers={})
        headers.each { |k,v| set_header(k, v) }
        @headers
      end

      def [](url, params={})
        Request.new(self, url, params)   
      end

      def inspect
        "(Session)"
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
    end
  end
end

