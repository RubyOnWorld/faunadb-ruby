module Fauna
  class Resource
    def self.find(ref)
      alloc(Fauna::Client.get(ref))
    end

    def self.find_by_constraint(fauna_class, path, term)
      escaped_path= CGI.escape(path)
      escaped_term = CGI.escape(term)
      alloc(Fauna::Client.get("#{fauna_class}/constraints/#{escaped_path}/#{escaped_term}"))
    end

    def self.create(fauna_class, *args)
      new(fauna_class, *args).tap { |obj| obj.save }
    end

    def self.alloc(struct)
      obj = allocate
      obj.instance_variable_set('@struct', struct)
      obj
    end

    def self.time_from_usecs(microseconds)
      Time.at(microseconds/1_000_000, microseconds % 1_000_000)
    end

    def self.usecs_from_time(time)
      time.to_i * 1000000 + time.usec
    end

    attr_reader :struct

    alias :to_hash :struct

    def initialize(fauna_class, attrs = {})
      @struct = { 'ref' => nil, 'ts' => nil, 'deleted' => false, 'class' => fauna_class }
      assign(attrs)
    end

    def ts
      struct['ts'] ? Resource.time_from_usecs(struct['ts']) : nil
    end

    def ts=(time)
      struct['ts'] = Resource.usecs_from_time(time)
    end

    def ref; struct['ref'] end
    def fauna_class; struct['class'] end
    def deleted; struct['deleted'] end
    def constraints; struct['constraints'] ||= {} end
    def data; struct['data'] ||= {} end
    def references; struct['references'] ||= {} end

    def eql?(other)
      self.fauna_class == other.fauna_class && self.ref == other.ref && self.ref != nil
    end
    alias :== :eql?

    # dynamic field access

    def respond_to?(method, *args)
      !!getter_method(method) || !!setter_method(method) || super
    end

    def method_missing(method, *args)
      if field = getter_method(method)
        struct[field]
      elsif field = setter_method(method)
        struct[field] = args.first
      else
        super
      end
    end

    # object lifecycle

    def new_record?; ref.nil? end

    def deleted?; deleted end

    def persisted?; !(new_record? || deleted?) end

    def save
      @struct = (new_record? ? post : put).to_hash
    end

    def update(attributes = {})
      assign(attributes)
      save
    end

    def delete
      Fauna::Client.delete(ref) if persisted?
      struct['deleted'] = true
      struct.freeze
      nil
    end

    private

    # TODO: make this configurable, and possible to invert to a white list
    UNASSIGNABLE_ATTRIBUTES = %w(ts deleted fauna_class).inject({}) { |h, attr| h.update attr => true }

    def assign(attributes)
      attributes.each do |name, val|
        send "#{name}=", val unless UNASSIGNABLE_ATTRIBUTES[name.to_s]
      end
    end

    def put
      Fauna::Client.put(ref, struct)
    end

    def post
      Fauna::Client.post(fauna_class, struct)
    end

    def getter_method(method)
      field = method.to_s
      struct.include?(field) ? field : nil
    end

    def setter_method(method)
      (/(.*)=$/ =~ method.to_s) ? $1 : nil
    end
  end
end
