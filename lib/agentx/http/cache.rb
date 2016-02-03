
module AgentX
  module Http
    class Cache
      def self.store_path
        return @store_path if @store_path

        @store_path = File.join(AgentX.root, 'cache')

        unless Dir.exists?(@store_path)
          Dir.mkdir(@store_path)
        end

        @store_path
      end

      def self.path(request)
        File.join(store_path, "#{request.cache_key}.json")
      end

      def self.db
        @db ||= Database.new
      end

      def self.write(request, response)
        db.write(
          request_cache_key:       request.cache_key,
          request_host:            request.host,
          request_base_url:        request.base_url,
          response_code:           response.code,
          response_headers:        Oj.dump(response.headers.to_hash),
          response_content_length: response.body.length,
          response_expires_at:     response.expires_at,
          response_body:           response.body)
      end

      def self.read(request)
        if h = db.read(request.cache_key)
          Response.new(
            h['response_code'],
            h['response_body'],
            Oj.load(h['response_headers']))
        end
      end

      class Database
        attr_reader :filename

        def initialize(filename=File.join(AgentX.root, 'cache.sqlite3'))
          @filename = filename

          create
        end

        def create
          if File.exists?(filename)
            return @db = SQLite3::Database.new(filename)
          end

          @db = SQLite3::Database.new(filename)

          @db.execute(<<-SQL)
            CREATE TABLE responses (
              request_cache_key       STRING PRIMARY KEY,
              request_host            STRING,
              request_base_url        STRING,
              response_code           INTEGER,
              response_headers        TEXT,
              response_content_length INTEGER,
              response_expires_at     INTEGER,
              response_body           BLOB)
          SQL

          @db.execute(<<-SQL)
            CREATE INDEX responses_expires_at ON responses (response_expires_at)
          SQL

          @db.execute(<<-SQL)
            CREATE INDEX responses_host ON responses (request_host)
          SQL

          @db
        end

        INSERT_SQL = <<-SQL
          INSERT OR REPLACE INTO responses (
            request_cache_key, 
            request_host, 
            request_base_url,
            response_code,
            response_headers,
            response_content_length,
            response_expires_at,
            response_body) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        SQL

        def write(opts={})
          @prepared_write ||= @db.prepare(INSERT_SQL)

          @prepared_write.execute(
            opts[:request_cache_key],
            opts[:request_host],
            opts[:request_base_url],
            opts[:response_code],
            opts[:response_headers],
            opts[:response_content_length],
            opts[:response_expires_at].to_i,
            opts[:response_body])
        end

        SELECT_BY_CACHE_KEY_SQL = <<-SQL
          SELECT * FROM responses WHERE request_cache_key = ?
        SQL

        def read(cache_key)
          @prepared_read ||= @db.prepare(SELECT_BY_CACHE_KEY_SQL)

          rs = @prepared_read.execute(cache_key)
          rs.next_hash
        end

      end
    end
  end
end

