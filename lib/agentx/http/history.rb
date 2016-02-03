
module AgentX
  module Http

    class History
      include Enumerable

      def initialize
        @entries = []
      end

      def add(request, response)
        @entries << Entry.new(request, response)
      end

      def [](n)
        @entries[n]
      end

      def first
        @entries.first
      end

      def last
        @entries.last
      end

      def length
        @entries.length
      end

      def each(&block)
        @entries.each(&block)
      end

      class Entry
        attr_reader :request, :response

        def initialize(request, response)
          @request, @response = request, response
        end

        def inspect
          [request, response].inspect
        end
      end

    end
  end
end

