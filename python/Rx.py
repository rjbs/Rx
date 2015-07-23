
import re
import types
from numbers import Number

core_types = [ ]

class SchemaError(Exception):
  pass

class DataError(Exception):
  pass

class Util(object):
  @staticmethod
  def make_range_check(opt):

    if not {'min', 'max', 'min-ex', 'max-ex'}.issuperset(opt.keys()):
      raise ValueError("illegal argument to make_range_check")

    r = opt.copy()

    def check_range(value):
      inf = float('inf')
      return(
        r.get('min',    -inf) <= value and \
        r.get('max',     inf) >= value and \
        r.get('min-ex', -inf) <  value and \
        r.get('max-ex',  inf) >  value
        )

    return check_range

class Factory(object):
  def __init__(self, opt={}):
    self.prefix_registry = {
      '':      'tag:codesimply.com,2008:rx/core/',
      '.meta': 'tag:codesimply.com,2008:rx/meta/',
    }

    self.type_registry = {}
    if opt.get('register_core_types', False):
      for t in core_types: self.register_type(t)

  @staticmethod
  def _default_prefixes(): pass

  def expand_uri(self, type_name):
    if re.match('^\w+:', type_name): return type_name

    m = re.match('^/([-._a-z0-9]*)/([-._a-z0-9]+)$', type_name)

    if not m:
      raise ValueError("couldn't understand type name '%s'" % type_name)

    if not self.prefix_registry.get(m.group(1)):
      raise ValueError(
        "unknown prefix '%s' in type name '%s'" % (m.group(1), type_name)
      )

    return '%s%s' % (self.prefix_registry[ m.group(1) ], m.group(2))

  def add_prefix(self, name, base):
    if self.prefix_registry.get(name):
      raise SchemaError("the prefix '%s' is already registered" % name)

    self.prefix_registry[name] = base;

  def register_type(self, t):
    t_uri = t.uri()

    if self.type_registry.get(t_uri):
      raise ValueError("type already registered for %s" % t_uri)

    self.type_registry[t_uri] = t

  def learn_type(self, uri, schema):
    if self.type_registry.get(uri):
      raise SchemaError("tried to learn type for already-registered uri %s" % uri)

    # make sure schema is valid
    # should this be in a try/except?
    self.make_schema(schema)

    self.type_registry[uri] = { 'schema': schema }

  def make_schema(self, schema):
    if isinstance(schema, str):
      schema = { 'type': schema }

    if not isinstance(schema, dict):
      raise SchemaError('invalid schema argument to make_schema')

    uri = self.expand_uri(schema['type'])

    if not self.type_registry.get(uri): raise SchemaError("unknown type %s" % uri)

    type_class = self.type_registry[uri]

    if isinstance(type_class, dict):
      if not {'type'}.issuperset(schema.keys()):
        raise SchemaError('composed type does not take check arguments');
      return self.make_schema(type_class['schema'])
    else:
      return type_class(schema, self)

class _CoreType(object):
  @classmethod
  def uri(self):
    return 'tag:codesimply.com,2008:rx/core/' + self.subname()

  def __init__(self, schema, rx):
    if not {'type'}.issuperset(schema.keys()):
      raise SchemaError('unknown parameter for //%s' % self.subname())

  def check(self, value): return False

class AllType(_CoreType):
  @staticmethod
  def subname(): return 'all'

  def __init__(self, schema, rx):
    if not {'type', 'of'}.issuperset(schema.keys()):
      raise SchemaError('unknown parameter for //all')
    
    if not(schema.get('of') and len(schema.get('of'))):
      raise SchemaError('no alternatives given in //all of')

    self.alts = [rx.make_schema(s) for s in schema['of']]

  def check(self, value):
    return all(schema.check(value) for schema in self.alts)

class AnyType(_CoreType):
  @staticmethod
  def subname(): return 'any'

  def __init__(self, schema, rx):
    self.alts = None

    if not {'type', 'of'}.issuperset(schema.keys()):
      raise SchemaError('unknown parameter for //any')
    
    if schema.get('of') is not None:
      if not schema['of']: raise SchemaError('no alternatives given in //any of')
      self.alts = [ rx.make_schema(alt) for alt in schema['of'] ]

  def check(self, value):
    if self.alts is None: return True

    return any(schema.check(value) for schema in self.alts)

class ArrType(_CoreType):
  @staticmethod
  def subname(): return 'arr'

  def __init__(self, schema, rx):
    self.length = None

    if not {'type', 'contents', 'length'}.issuperset(schema.keys()):
      raise SchemaError('unknown parameter for //arr')

    if not schema.get('contents'):
      raise SchemaError('no contents provided for //arr')

    self.content_schema = rx.make_schema(schema['contents'])

    if schema.get('length'):
      self.length = Util.make_range_check(schema['length'])

  def check(self, value):
    if not isinstance(value, (list, tuple)): return False
    if self.length and not self.length(len(value)): return False

    return all(self.content_schema.check(item) for item in value)

class BoolType(_CoreType):
  @staticmethod
  def subname(): return 'bool'

  def check(self, value):
    return isinstance(value, bool)

class DefType(_CoreType):
  @staticmethod
  def subname(): return 'def'

  def check(self, value): return value is not None

class FailType(_CoreType):
  @staticmethod
  def subname(): return 'fail'

  def check(self, value): return False

class IntType(_CoreType):
  @staticmethod
  def subname(): return 'int'

  def __init__(self, schema, rx):
    if not {'type', 'range', 'value'}.issuperset(schema.keys()):
      raise SchemaError('unknown parameter for //int')

    self.value = None
    if 'value' in schema:
      if not isinstance(schema['value'], Number) or schema['value'] % 1 != 0:
        raise SchemaError('invalid value parameter for //int')
      self.value = schema['value']

    self.range = None
    if 'range' in schema:
      self.range = Util.make_range_check(schema['range'])

  def check(self, value):
    return (
      isinstance(value, Number) and \
      not isinstance(value, bool) and \
      value%1 == 0 and \
      (self.range is None or self.range(value)) and \
      (self.value is None or value == self.value)
      )
      

class MapType(_CoreType):
  @staticmethod
  def subname(): return 'map'

  def __init__(self, schema, rx):
    self.allowed = set()

    if not {'type', 'values'}.issuperset(schema.keys()):
      raise SchemaError('unknown parameter for //map')

    if not schema.get('values'):
      raise SchemaError('no values given for //map')

    self.value_schema = rx.make_schema(schema['values'])

  def check(self, value):
    if not isinstance(value, dict): return False

    return all(self.value_schema.check(v) for v in value.values())

class NilType(_CoreType):
  @staticmethod
  def subname(): return 'nil'

  def check(self, value): return value is None

class NumType(_CoreType):
  @staticmethod
  def subname(): return 'num'

  def __init__(self, schema, rx):
    if not {'type', 'range', 'value'}.issuperset(schema.keys()):
      raise SchemaError('unknown parameter for //num')

    self.value = None
    if 'value' in schema:
      if not isinstance(schema['value'], Number):
        raise SchemaError('invalid value parameter for //num')
      self.value = schema['value']

    self.range = None

    if schema.get('range'):
      self.range = Util.make_range_check( schema['range'] )

  def check(self, value):
    return (
      isinstance(value, Number) and \
      not isinstance(value, bool) and \
      (self.range is None or self.range(value)) and \
      (self.value is None or value == self.value)
      )
      

class OneType(_CoreType):
  @staticmethod
  def subname(): return 'one'

  def check(self, value):
    return isinstance(value, (Number, str))

class RecType(_CoreType):
  @staticmethod
  def subname(): return 'rec'

  def __init__(self, schema, rx):
    if not {'type', 'rest', 'required', 'optional'}.issuperset(schema.keys()):
      raise SchemaError('unknown parameter for //rec')

    self.known = set()
    self.rest_schema = None
    if schema.get('rest'): self.rest_schema = rx.make_schema(schema['rest'])

    for which in ('required', 'optional'):
      self.__setattr__(which, { })
      for field in schema.get(which, {}).keys():
        if field in self.known:
          raise SchemaError('%s appears in both required and optional' % field)

        self.known.add(field)

        self.__getattribute__(which)[field] = rx.make_schema(
          schema[which][field]
        )

  def check(self, value):
    if not isinstance(value, dict): return False

    unknown = [k for k in value.keys() if k not in self.known]

    if unknown and not self.rest_schema: return False

    if not all(
        k in value and self.required[k].check(value[k]) for k in self.required):
      return False

    if not all(
        self.optional[k].check(value[k]) for k in self.optional if k in value):
      return False

    if unknown:
      rest = {key: value[key] for key in unknown}
      if not self.rest_schema.check(rest): return False

    return True

class SeqType(_CoreType):
  @staticmethod
  def subname(): return 'seq'

  def __init__(self, schema, rx):
    if not {'type', 'contents', 'tail'}.issuperset(schema.keys()):
      raise SchemaError('unknown parameter for //seq')

    if not schema.get('contents'):
      raise SchemaError('no contents provided for //seq')

    self.content_schema = [ rx.make_schema(s) for s in schema['contents'] ]

    self.tail_schema = None
    if (schema.get('tail')):
      self.tail_schema = rx.make_schema(schema['tail'])

  def check(self, value):
    if not isinstance(value, (list, tuple)): return False

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
    if not {'type', 'value', 'length'}.issuperset(schema.keys()):
      raise SchemaError('unknown parameter for //str')

    self.value = None
    if 'value' in schema:
      if not isinstance(schema['value'], str):
        raise SchemaError('invalid value parameter for //str')
      self.value = schema['value']

    self.length = None
    if 'length' in schema:
      self.length = Util.make_range_check( schema['length'] )

  def check(self, value):
    if not isinstance(value, str): return False
    if (not self.value is None) and value != self.value: return False
    if self.length and not self.length(len(value)): return False
    return True

core_types = [
  AllType,  AnyType, ArrType, BoolType, DefType,
  FailType, IntType, MapType, NilType,  NumType,
  OneType,  RecType, SeqType, StrType
]
