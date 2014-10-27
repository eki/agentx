
module AgentX

  class Response
    attr_reader :code, :body, :headers

    def initialize(code, body, headers)
      @code, @body, @headers = code, body, Headers.parse(headers)
    end

    def self.from_easy(easy, response=nil)
      headers = Headers.parse(easy.response_headers)

      r = new(easy.response_code, easy.response_body, headers)

      if response && r.not_modified?
        r = new(response.code, response.body, response.headers.merge(r.headers))
      end

      r
    end

    def cookies
      Array(headers.set_cookie || [])
    end

    def ok?
      code == 200
    end

    def not_modified?
      code == 304
    end

    def fresh?
      headers.ttl && headers.ttl > 0
    end

    def expires_at
      headers.ttl ? Time.now + headers.ttl : Time.at(0)
    end

    CACHEABLE_CODES = [200, 203, 300, 301, 302, 404, 410]

    def cacheable?
      return false if headers.cache_control && headers.cache_control.no_store?
      return false unless CACHEABLE_CODES.include?(code)

      !! (headers.etag || headers.last_modified || fresh?)
    end

    def inspect
      "(Response #{code})"
    end

    def to_hash
      { 'code'    => code,
        'body'    => body,
        'headers' => headers.to_hash }
    end

    def self.from_hash(h)
      new(h['code'], h['body'], h['headers'])
    end

    def parse(type=nil)
      case
        when type == :json || headers.json? then Oj.load(body)
        when type == :html || headers.html? then HTML.new(body)
        when type == :xml  || headers.xml?  then XML.new(body)
                                            else body
      end
    end

    class Headers
      include Enumerable

      def initialize(hash={})
        @hash = hash
        @hash['Date'] ||= Time.now.httpdate
        @normalized = {}
        @hash.each do |k,v|
          @normalized[k.to_s.downcase] = v
        end
      end

      def self.parse(str)
        return new(str) if str.kind_of?(Hash)
        return str      if str.kind_of?(Headers)

        hash = {}

        str.lines.each do |line|
          next if line =~ /^HTTP\/\d/
          k, v = line.split(':', 2).map { |s| s.strip }

          if k && v
            if hash[k]
              hash[k] = Array(hash[k])
              hash[k] << v
            else
              hash[k] = v
            end
          end
        end

        new(hash)
      end

      def merge(headers)
        Headers.new(to_hash.merge(headers.to_hash))
      end

      def inspect
        "(Headers #{@normalized})"
      end

      def each(&block)
        @normalized.each(&block)
      end

      def [](k)
        @hash[k] || @normalized[k.to_s.downcase]
      end

      def server
        @normalized['server']
      end

      def date
        Time.parse(@normalized['date'])
      end

      def age
        (@normalized['age'] || (Time.now - date)).to_i
      end

      def expires
        if d = @normalized['expires']
          Time.parse(d)
        end
      end

      def max_age
        (cache_control && 
         (cache_control.shared_max_age || cache_control.max_age)) ||
        (expires && (expires - Time.now))
      end

      def ttl
        max_age && (max_age - age)
      end

      def last_modified
        @normalized['last-modified']
      end

      def etag
        @normalized['etag']
      end

      def content_type
        @normalized['content-type']
      end

      def json?
        content_type.to_s.downcase['json']
      end

      def html?
        content_type.to_s.downcase['html']
      end

      def xml?
        content_type.to_s.downcase['xml']
      end

      def content_length
        if (length = @normalized['content-length']) && length =~ /^\d+$/
          length.to_i
        end
      end

      def cache_control
        if @normalized['cache-control']
          @cache_control ||= CacheControl.parse(@normalized['cache-control'])
        end
      end

      def set_cookie
        @normalized['set-cookie']
      end

      def location
        @normalized['location']
      end

      def to_hash
        @hash
      end

      class CacheControl
        attr_reader :directives

        def initialize(directives)
          @directives = directives
        end

        def public?
          @directives['public']
        end

        def private?
          @directives['private']
        end

        def no_store?
          @directives['no-store']
        end

        def no_cache?
          @directives['no-cache']
        end

        def must_revalidate?
          @directives['must-revalidate']
        end

        def max_age
          @directives['max-age'] && @directives['max-age'].to_i
        end

        def shared_max_age
          @directives['s-max-age'] && @directives['s-max-age'].to_i
        end

        def to_s
          directives.map { |k,v| v == true ? k : "#{k}=#{v}" }.join(', ')
        end

        def inspect
          "(CacheControl #{directives})"
        end

        def self.parse(s)
          h = {}

          Array(s).join(',').gsub(' ', '').split(',').each do |p|
            k, v = p.split('=')

            h[k.downcase] = (v || true)
          end

          new(h)
        end
      end
    end
  end

end

