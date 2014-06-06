
module AgentX

  class CookieJar
    def initialize
      @jar = {}
    end

    def store(cookie)
      cookie = Cookie.parse(cookie) if cookie.kind_of?(String)
      @jar[cookie.name] ||= []
      @jar[cookie.name] << cookie
    end

    def cookies_by_name(name)
      @jar[name]
    end

    def all
      @jar.values.flatten
    end

    private

    class Cookie
      attr_reader :name, :value

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
        @expires ||= Time.parse(@opts['expires'])
      end

      def inspect
        ary = ["domain: #{domain}", "path: #{path}", "expires: #{expires}"]
        ary << 'HttpOnly' if http_only?
        ary << 'secure' if secure?

        "(Cookie #{name}=#{value} #{ary.join(', ')})"
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

