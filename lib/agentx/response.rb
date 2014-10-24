
module AgentX

  class Response
    attr_reader :code, :body, :headers

    def initialize(code, body, headers)
      @code, @body, @headers = code, body, Headers.parse(headers)
    end

    def self.from_easy(easy)
      new(easy.response_code, easy.response_body, easy.response_headers)
    end

    def cookies
      Array(headers.set_cookie || [])
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
      def initialize(hash={})
        @hash = hash
        @normalized = {}
        @hash.each do |k,v|
          @normalized[k.to_s.downcase] = v
        end
      end

      def self.parse(str)
        return new(str) if str.kind_of?(Hash)

        hash = {}

        str.lines.each do |line|
          next if line =~ /^HTTP\/\d/
          k, v = line.split(':', 2).map { |s| s.strip }
          if hash[k]
            hash[k] = Array(hash[k])
            hash[k] << v
          else
            hash[k] = v
          end
        end

        new(hash)
      end

      def [](k)
        @hash[k] || @normalized[k.to_s.downcase]
      end

      def server
        @normalized['server']
      end

      def date
        if d = @normalized['date']
          Time.parse(d)
        end
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

      def set_cookie
        @normalized['set-cookie']
      end

      def location
        @normalized['location']
      end

      def to_hash
        @hash
      end
    end
  end

end

