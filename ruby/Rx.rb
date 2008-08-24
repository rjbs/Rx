
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
    @@allowed = { 'of' => true, 'type' => true }

    def initialize(param, rx)
      param.each_key { |k|
        unless @@allowed[k] then
          raise Rx::Exception.new("unknown parameter #{k} for //any")
        end
      }

      if param['of'] then
        @alts = [ ]
        param['of'].each { |alt| @alts.push(rx.make_schema(alt)) }
      end
    end

    def authority; return ''   ; end
    def subname  ; return 'any'; end

    def check(value)
      return true unless @alts

      @alts.each { |alt| return true if alt.check(value) }

      return false
    end
  end

  class Arr < Rx::Type::Core
    @@allowed = { 'contents' => true, 'length' => true, 'type' => true }

    def initialize(param, rx)
      unless param['contents'] then
        raise Rx::Exception.new('no contents schema given for //arr')
      end

      param.each_key { |k|
        unless @@allowed[k] then
          raise Rx::Exception.new("unknown parameter #{k} for //arr")
        end
      }

      @contents_schema = rx.make_schema( param['contents'] )

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
    @@allowed = { 'range' => true, 'type' => true }

    def initialize(param, rx)
      param.each_key { |k|
        unless @@allowed[k] then
          raise Rx::Exception.new("unknown parameter #{k} for //int")
        end
      }

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
    def initialize(param, rx)
      if param['values'] then
        @value_schema = rx.make_schema(param['values'])
      end
    end

    def check(value)
      return false unless value.instance_of?(Hash)

      if @value_schema
        value.each_value { |v| return false unless @value_schema.check(v) }
      end

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
    @@allowed = {
      'type' => true,
      'rest' => true,
      'required' => true,
      'optional' => true,
    }

    def initialize(param, rx)
      param.each_key { |k|
        unless @@allowed[k] then
          raise Rx::Exception.new("unknown parameter #{k} for //rec")
        end
      }

      @field = { }

      @rest_schema = rx.make_schema(param['rest']) if param['rest']

      [ 'optional', 'required' ].each { |type|
        next unless param[type]
        param[type].keys.each { |field|
          if @field[field] then
            raise Rx::Exception.new("#{field} in both required and optional")
          end

          @field[field] = {
            :required => (type == 'required'),
            :schema   => rx.make_schema(param[type][field]),
          }
        }
      }
    end

    def check(value)
      return false unless value.instance_of?(Hash)

      rest = [ ]

      value.each_pair { |field, field_value|
        unless @field[field] then
          rest.push(field)
          next
        end

        return false unless @field[field][:schema].check(field_value)
      }

      @field.select { |k,v| @field[k][:required] }.each { |pair|
        return false unless value.has_key?(pair[0])
      }

      if rest.length > 0 then
        return unless @rest_schema
        rest_hash = { }
        rest.each { |field| rest_hash[field] = value[field] }
        return false unless @rest_schema.check(rest_hash)
      end

      return true
    end
  end

  class Seq < Rx::Type::Core
    @@allowed = { 'tail' => true, 'contents' => true, 'type' => true }

    def initialize(param, rx)
      param.each_key { |k|
        unless @@allowed[k] then
          raise Rx::Exception.new("unknown parameter #{k} for //seq")
        end
      }

      unless param['contents'] and param['contents'].kind_of?(Array) then
        raise Rx::Exception.new('missing or invalid contents for //seq')
      end

      @content_schemata = param['contents'].map { |s| rx.make_schema(s) }

      if param['tail'] then
        @tail_schema = rx.make_schema(param['tail'])
      end
    end

    def check(value)
      return false unless value.instance_of?(Array)
      return false if value.length < @content_schemata.length

      @content_schemata.each_index { |i|
        return false unless @content_schemata[i].check(value[i])
      }

      if value.length > @content_schemata.length then
        return false unless @tail_schema and @tail_schema.check(value[
          @content_schemata.length,
          value.length - @content_schemata.length
        ])
      end

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

