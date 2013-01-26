
module Fauna
  class Client

    class NoContextError < StandardError
    end

    class CachingContext
      def initialize(connection)
        @cache = {}
        @connection = connection
      end

      def get(ref)
        res = @connection.get(ref)
        cohere(res)
        res['resource']
      end

      def post(ref, data)
        res = @connection.post(ref, data)
        cohere(res)
        res['resource']
      end

      def put(ref, data)
        res = @connection.put(ref, data)
        cohere(res)
        res['resource']
      end

      def delete(ref, data)
        @connection.delete(ref, data)
        @cache.delete(ref)
        nil
      end

      private

      def cohere(res)
        resource = res['resource']
        @cache[resource.ref] = resource
        @cache.merge!(res['references'])
      end
    end

    def self.context(connection)
      @stack ||= {}
      @stack[Thread.current] ||= []
      @stack[Thread.current].push(CachingContext.new(connection))
      yield
      @stack[Thread.current].pop
    end

    def self.get(ref)
      this.get(ref)
    end

    def self.post(ref, data = {})
      this.post(ref, data)
    end

    def self.put(ref, data = {})
      this.put(ref, data)
    end

    def self.delete(ref, data = {})
      this.delete(ref, data)
    end

    def self.this
      @stack[Thread.current].last or raise NoContextError, "You must be within a Fauna::Client.context block to perform operations."
    end
  end
end
