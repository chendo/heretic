class Heretic
  class RemoteObjectProxy
    attr_reader :created_at, :object_proxy_id, :transport

    def initialize(object_proxy_id, transport)
      @object_proxy_id = object_proxy_id
      @created_at = Time.now
      @transport = transport
    end

    def ==(other)
      object_proxy_id == other.object_proxy_id
    end

    def to_json(*args)
      {
        :__object_proxy_id => object_proxy_id,
      }.to_json(*args)
    end

    def method_missing(method_name, *args)
      transport.call(object_proxy_id, method_name, args)
    end
  end
end
