
class Rx
  def initialize(opt={})
    @registry = { }

    if opt[:load_core] then
      @registry[''] = {
        'any'  => Rx::Type::Core::Any,
        'arr'  => Rx::Type::Core::Arr,
        'bool' => Rx::Type::Core::Bool,
        'def'  => Rx::Type::Core::Def,
        'int'  => Rx::Type::Core::Int,
        'map'  => Rx::Type::Core::Map,
        'nil'  => Rx::Type::Core::Nil,
        'num'  => Rx::Type::Core::Num,
        'one'  => Rx::Type::Core::One,
        'rec'  => Rx::Type::Core::Rec,
        'seq'  => Rx::Type::Core::Seq,
        'str'  => Rx::Type::Core::Str,
      }
    end
  end

  def parse_name(schema_name)
    match = schema_name.match(/\A\/([-._a-z0-9]*)\/([-._a-z0-9]+)\z/)
    raise Rx::Exception.new('invalid schema name') unless match
    return { :authority => match[1], :subname => match[2] }
  end

  def make_schema(schema)
    schema = { 'type' => schema } if schema.instance_of?(String)

    if not (schema.instance_of?(Hash) and schema['type']) then
      raise Rx::Exception.new('invalid type')
    end

    sn = parse_name(schema['type'])

    authority = @registry[ sn[:authority] ]
    raise Rx::Exception.new('unknown authority') unless authority

    type_class = authority[ sn[:subname] ]
    raise Rx::Exception.new('unknown subname') unless type_class

    return type_class.new(schema, self)
  end
end

class Rx::Helper; end;
class Rx::Helper::Range
  def initialize(rule, arg)
    rule.default = true

    # allow_negative",  True)
    # allow_fraction",  True)
    # allow_exclusive", True)

    @range = { }

    arg.each_pair { |key,value|
      if not ['min', 'max', 'min-ex', 'max-ex'].index(key) then
        raise Rx::Exception.new("illegal argument for Rx::Helper::Range")
      end

      if key.match(/-ex\z/) and not rule[:allow_exclusive] then
        raise Rx::Exception.new(
          "given exclusive argument for range when not allowed"
        )
      end

      if value < 0 and not rule[:allow_negative] then
        raise Rx::Exception.new(
          "given negative value for range when not allowed"
        )
      end

      if (value % 1 != 0) and not rule[:allow_fraction] then
        raise Rx::Exception.new(
          "given fractional value for range when not allowed"
        )
      end

      @range[ key ] = value
    }
  end

  def check(value)
    return false if ! @range['min'   ].nil? and value <  @range['min'   ]
    return false if ! @range['min-ex'].nil? and value <= @range['min-ex']
    return false if ! @range['max-ex'].nil? and value >= @range['max-ex']
    return false if ! @range['max'   ].nil? and value >  @range['max'   ]
    return true
  end
end

class Rx::Type
  def check(value)
    raise Rx::Exception.new("Rx::Type subclass didn't implement .new")
  end

  module NoParams
    def initialize(param, rx)
      return if param.keys.length == 0
      return if param.keys == [ 'type' ]

      raise Rx::Exception.new('this type is not parameterized')
    end
  end
end

class Rx::Exception < Exception
end

class Rx::Type::Core < Rx::Type
  class Any < Rx::Type::Core
    include Rx::Type::NoParams
    def authority; return ''   ; end
    def subname  ; return 'any'; end

    def check(value); return true; end
  end

  class Arr < Rx::Type::Core
    def initialize(param, rx)
      if param['contents'] then
        @contents_schema = rx.make_schema( param['contents'] )
      end

      if param['length'] then
        @length_range = Rx::Helper::Range.new(
          {
            :allow_exclusive  => false,
            :allow_fractional => false,
            :allow_negative   => false,
          },
          param['length']
        )
      end
    end

    def check(value)
      return false unless value.instance_of?(Array)

      if @length_range
        return false unless @length_range.check(value.length)
      end

      if @contents_schema then
        value.each { |v| return false unless @contents_schema.check(v) }
      end

      return true
    end
  end

  class Bool < Rx::Type::Core
    include Rx::Type::NoParams

    def check(value)
      return true if value.instance_of?(TrueClass)
      return true if value.instance_of?(FalseClass)
      return false
    end
  end

  class Def < Rx::Type::Core
    include Rx::Type::NoParams
    def check(value); return ! value.nil?; end
  end

  class Int < Rx::Type::Core
    def initialize(param, rx)
      if param['range'] then
        @value_range = Rx::Helper::Range.new(
          {
            :allow_fractional => false,
          },
          param['range']
        )
      end
    end

    def check(value)
      if not value.kind_of?(Numeric) then; return false; end;
      if value % 1 != 0 then; return false; end
      return false if @value_range and not @value_range.check(value)
      return true;
    end
  end

  class Map < Rx::Type::Core
    def initialize(param, rx); end;

    def check(value)
      return false unless value.instance_of?(Hash)
      return true
    end
  end

  class Nil < Rx::Type::Core
    include Rx::Type::NoParams
    def check(value); return value.nil?; end
  end

  class Num < Rx::Type::Core
    def initialize(param, rx)
      if param['range'] then
        @value_range = Rx::Helper::Range.new(
          { },
          param['range']
        )
      end
    end

    def check(value)
      if not value.kind_of?(Numeric) then; return false; end;
      return false if @value_range and not @value_range.check(value)
      return true;
    end
  end

  class One < Rx::Type::Core
    include Rx::Type::NoParams

    def check(value)
      [ Numeric, String, TrueClass, FalseClass ].each { |cls|
        return true if value.kind_of?(cls)
      }

      return false
    end
  end

  class Rec < Rx::Type::Core
    def initialize(param, rx);
    end;

    def check(value)
      return false unless value.instance_of?(Hash)
      return true
    end
  end

  class Seq < Rx::Type::Core
    def initialize(param, rx); end;

    def check(value)
      return false unless value.instance_of?(Array)
      return true
    end
  end

  class Str < Rx::Type::Core
    def initialize(param, rx); end;

    def check(value)
      return false unless value.instance_of?(String)
      return true
    end
  end
end

