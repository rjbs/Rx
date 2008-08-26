
import re
import types

core_types = [ ]

class Error(Exception):
  pass

class Util(object):
  @staticmethod
  def parse_type_name(type_name):
    m = re.match('^/([-._a-z0-9]*)/([-._a-z0-9]+)$', type_name)

    return {
      "authority": m.group(1),
      "subname"  : m.group(2),
    }

  @staticmethod
  def make_range_check(opt):
    range = { }
    for entry in opt.keys():
      if entry not in ('min', 'max', 'min-ex', 'max-ex'):
        raise "illegal argument to make_range_check"

      range[entry] = opt[entry]

    def check_range(value):
      if range.get('min'   ) != None and value <  range['min'   ]: return False
      if range.get('min-ex') != None and value <= range['min-ex']: return False
      if range.get('max-ex') != None and value >= range['max-ex']: return False
      if range.get('max'   ) != None and value >  range['max'   ]: return False
      return True

    return check_range

class Factory(object):
  def __init__(self, opt={}):
    self.registry = {}
    if opt.get("register_core_types", False):
      for t in core_types: self.register_type(t)

  def register_type(self, t):
    t_authority = t.authority()
    t_subname   = t.subname()

    self.registry.setdefault(t_authority, {})

    if self.registry[t_authority].get(t_subname, None):
      raise "type already registered for /%s/%s" % (t_authority, t_subname)

    self.registry[t_authority][t_subname] = t

  def make_schema(self, schema):
    if type(schema) in (str, unicode):
      schema = { "type": schema }

    if not type(schema) is dict:
      raise Error('invalid schema argument to make_schema')
  
    sn = Util.parse_type_name(schema["type"])

    if not self.registry.has_key(sn["authority"]):
      raise "unknown authority in type %s" % schema["type"]

    if not self.registry[ sn["authority"] ].has_key(sn["subname"]):
      raise "unknown subname in type %s" % schema["type"]

    type_class = self.registry[ sn["authority"] ][ sn["subname"] ]

    return type_class(schema, self)

class _CoreType(object):
  @staticmethod
  def authority(): return ''

  def __init__(self, schema, rx): pass

  def check(self, value): return False

class AllType(_CoreType):
  @staticmethod
  def subname(): return 'all'

  def __init__(self, schema, rx):
    if not(schema.get('of') and len(schema.get('of'))):
      raise Error('no alternatives given in //all of')

    self.alts = [ rx.make_schema(s) for s in schema['of'] ]

  def check(self, value):
    for schema in self.alts:
      if (not schema.check(value)): return False
    return True

class AnyType(_CoreType):
  @staticmethod
  def subname(): return 'any'

  def __init__(self, schema, rx):
    self.alts = None

    if schema.get('of') != None:
      if not schema['of']: raise Error('no alternatives given in //any of')
      self.alts = [ rx.make_schema(alt) for alt in schema['of'] ]

  def check(self, value):
    if self.alts is None: return True
    
    for alt in self.alts:
      if alt.check(value): return True

    return False

class ArrType(_CoreType):
  @staticmethod
  def subname(): return 'arr'

  def __init__(self, schema, rx):
    self.length = None

    if not set(schema.keys()).issubset(set(('type', 'contents', 'length'))):
      raise Error('unknown parameter for //arr')
    
    if not schema.get('contents'):
      raise Error('no contents provided for //arr')

    self.content_schema = rx.make_schema(schema['contents'])

    if schema.get('length'):
      self.length = Util.make_range_check( schema["length"] )

  def check(self, value):
    if not(type(value) in [ type([]), type(()) ]): return False
    if self.length and not self.length(len(value)): return False

    for item in value:
      if not self.content_schema.check(item): return False

    return True;

class BoolType(_CoreType):
  @staticmethod
  def subname(): return 'bool'

  def check(self, value):
    if value is True or value is False: return True
    return False

class DefType(_CoreType):
  @staticmethod
  def subname(): return 'def'

  def check(self, value): return not(value is None)

class FailType(_CoreType):
  @staticmethod
  def subname(): return 'fail'

  def check(self, value): return False

class IntType(_CoreType):
  @staticmethod
  def subname(): return 'int'

  def __init__(self, schema, rx):
    if not set(schema.keys()).issubset(set(('type', 'range', 'value'))):
      raise Error('unknown parameter for //int')
    
    self.range = None
    if schema.get('range'):
      self.range = Util.make_range_check( schema["range"] )

  def check(self, value):
    if not(type(value) in (float, int, long)): return False
    if value % 1 != 0: return False
    if self.range and not self.range(value): return False
    return True

class MapType(_CoreType):
  @staticmethod
  def subname(): return 'map'

  def __init__(self, schema, rx):
    self.allowed = set()

    if not schema.get('values'):
      raise Error('no values given for //map')

    self.value_schema = rx.make_schema(schema['values'])

  def check(self, value):
    if not(type(value) is type({})): return False

    for v in value.values():
      if not self.value_schema.check(v): return False

    return True;

class NilType(_CoreType):
  @staticmethod
  def subname(): return 'nil'

  def check(self, value): return value is None

class NumType(_CoreType):
  @staticmethod
  def subname(): return 'num'

  def __init__(self, schema, rx):
    if not set(schema.keys()).issubset(set(('type', 'range', 'value'))):
      raise Error('unknown parameter for //num')

    self.range = None

    if schema.get('range'):
      self.range = Util.make_range_check( schema["range"] )

  def check(self, value):
    if not(type(value) in (float, int, long)): return False
    if self.range and not self.range(value): return False
    return True

class OneType(_CoreType):
  @staticmethod
  def subname(): return 'one'

  def check(self, value):
    if type(value) in (int, float, long, bool, str, unicode): return True

    return False

class RecType(_CoreType):
  @staticmethod
  def subname(): return 'rec'

  def __init__(self, schema, rx):
    if not set(schema.keys()).issubset(set(('type', 'rest', 'required', 'optional'))):
      raise Error('unknown parameter for //rec')

    self.known = set()
    self.rest_schema = None
    if schema.get('rest'): self.rest_schema = rx.make_schema(schema['rest'])

    for which in ('required', 'optional'):
      self.__setattr__(which, { })
      for field in schema.get(which, {}).keys():
        if field in self.known:
          raise Error('%s appears in both required and optional' % field)

        self.known.add(field)

        self.__getattribute__(which)[field] = rx.make_schema(
          schema[which][field]
        )

  def check(self, value):
    if not(type(value) is type({})): return False

    unknown = [ ]
    for field in value.keys():
      if not field in self.known: unknown.append(field)

    if len(unknown) and not self.rest_schema: return False

    for field in self.required.keys(): 
      if not value.has_key(field): return False
      if not self.required[field].check( value[field] ): return False

    for field in self.optional.keys():
      if not value.has_key(field): continue
      if not self.optional[field].check( value[field] ): return False

    if len(unknown):
      rest = { }
      for field in unknown: rest[field] = value[field]
      if not self.rest_schema.check(rest): return False

    return True;

class SeqType(_CoreType):
  @staticmethod
  def subname(): return 'seq'

  def __init__(self, schema, rx):
    if not schema.get('contents'):
      raise Error('no contents provided for //seq')

    self.content_schema = [ rx.make_schema(s) for s in schema["contents"] ]

    self.tail_schema = None
    if (schema.get('tail')):
      self.tail_schema = rx.make_schema(schema['tail'])

  def check(self, value):
    if not(type(value) in [ type([]), type(()) ]): return False

    if len(value) < len(self.content_schema):
      return False

    for i in range(0, len(self.content_schema)):
      if not self.content_schema[i].check(value[i]):
        return False

    if len(value) > len(self.content_schema):
      if not self.tail_schema: return False

      if not self.tail_schema.check(value[ len(self.content_schema) :  ]):
        return False

    return True;

class StrType(_CoreType):
  @staticmethod
  def subname(): return 'str'

  def __init__(self, schema, rx):
    if not set(schema.keys()).issubset(set(('type', 'value'))):
      raise Error('unknown parameter for //str')

  def check(self, value):
    return type(value) in (str, unicode)

core_types = [
  AllType,  AnyType, ArrType, BoolType, DefType,
  FailType, IntType, MapType, NilType,  NumType,
  OneType,  RecType, SeqType, StrType
]
