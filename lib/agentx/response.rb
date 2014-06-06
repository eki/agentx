
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

    def parse
      case
        when headers.json? then Oj.load(body)
        when headers.html? then Nokogiri::HTML(body)
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
        content_type.downcase['json']
      end

      def html?
        content_type.downcase['html']
      end

      def content_length
        if (length = @normalized['content-length']) && length =~ /^\d+$/
          length.to_i
        end
      end

      def set_cookie
        @normalized['set-cookie']
      end
    end
  end

end

