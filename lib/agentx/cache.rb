
module AgentX
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

    def self.write(request, response)
      open(path(request), 'w') do |f|
        f.puts(Oj.dump(response.to_hash, mode: :strict))
      end
    end

    def self.read(request)
      response = nil
      fp = path(request)

      if File.file?(fp)
        open(path(request), 'r') do |f|
          response = Response.from_hash(Oj.load(f.read))
        end
      end

      response
    end

  end
end

