
module AgentX

  class CookieJar
    def initialize
      @jar = []
    end

    def store(cookie, opts={})
      cookie = Cookie.parse(cookie) if cookie.kind_of?(String)
      cookie.from = URI(opts[:from])
      if cookie.valid?
        @jar.reject! do |c| 
          if cookie.exact_match?(c)
            puts "INFO: overwriting cookie #{c.inspect} for exact match #{cookie.inspect}"
            true
          end
        end
        @jar << cookie
      else
        puts "WARN: invalid cookie: #{cookie.inspect}"
      end
    end

    def all
      @jar
    end

    def match(url)
      @jar.select { |cookie| cookie =~ url }
    end

    private

    class Cookie
      attr_reader :name, :value
      attr_accessor :from

      def initialize(name, value, opts={})
        @name, @value, @opts = name, value, opts
      end

      def to_s
        "#{name}=#{value}"
      end

      def http_only?
        @opts.key?('HttpOnly')
      end

      def secure?
        @opts.key?('secure')
      end

      def domain
        @opts['domain']
      end

      def path
        @opts['path']
      end

      def expires
        if @opts['expires']
          @expires ||= Time.parse(@opts['expires'])
        end
      end

      def inspect
        ary = ["domain: #{domain}", "path: #{path}", "expires: #{expires}"]
        ary << 'HttpOnly' if http_only?
        ary << 'secure' if secure?
        ary << "from: #{from.to_s}" if from

        "(Cookie #{name}=#{value} #{ary.join(', ')})"
      end

      def =~(url)
        url = URI(url)

        return false if secure? && url.scheme != 'https'

        exact = false

        d = domain
        p = path

        unless d
          d = from.host
          exact = true
        end

        unless p
          p = from.path
          exact = true
        end

        url_path = url.path
        url_path = '/' if url_path.empty?

        if exact
          url.host == d && url_path == p
        else
          url.host.end_with?(d) && url_path.start_with?(p)
        end
      end

      def exact_match?(cookie)
        if name == cookie.name
          (domain || from.host) == (cookie.domain || cookie.from.host) &&
          (path || from.path) == (cookie.path || cookie.from.path)
        end
      end

      def valid?
        (! domain || domain =~ /\w+.\w+/ && from.host.end_with?(domain)) &&
        (! path || from.path.start_with?(path))
      end

      def self.parse(str)
        name, value, opts = nil, nil, {}

        str.split(/;\s+/).each do |pair|
          k, v = pair.split('=')

          if ! (name || value)
            name, value = k, v
          else
            opts[k] = v
          end
        end
  
        new(name, value, opts)
      end
    end

  end

end

