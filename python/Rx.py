import re
from six import string_types # for 2-3 compatibility
import types
from numbers import Number


core_types = [ ]

class SchemaError(Exception):
  pass

class SchemaMismatch(Exception):
  pass

class SchemaTypeMismatch(SchemaMismatch):
  def __init__(self, name, desired_type):
    SchemaMismatch.__init__(self, '{0} must be {1}'.format(name, desired_type))

class SchemaValueMismatch(SchemaMismatch):
  def __init__(self, name, value):
    SchemaMismatch.__init__(self, '{0} must equal {1}'.format(name, value))

class SchemaRangeMismatch(SchemaMismatch):
  pass

def indent(text, level=1, whitespace='  '):
    return '\n'.join(whitespace*level+line for line in text.split('\n'))

class Util(object):
  @staticmethod
  def make_range_check(opt):

    if not {'min', 'max', 'min-ex', 'max-ex'}.issuperset(opt):
      raise ValueError("illegal argument to make_range_check")
    if {'min', 'min-ex'}.issubset(opt):
      raise ValueError("Cannot define both exclusive and inclusive min")
    if {'max', 'max-ex'}.issubset(opt):
      raise ValueError("Cannot define both exclusive and inclusive max")      

    r = opt.copy()
    inf = float('inf')

    def check_range(value):
      return(
        r.get('min',    -inf) <= value and \
        r.get('max',     inf) >= value and \
        r.get('min-ex', -inf) <  value and \
        r.get('max-ex',  inf) >  value
        )

    return check_range

  @staticmethod
  def make_range_validator(opt):
    check_range = Util.make_range_check(opt)

    r = opt.copy()
    nan = float('nan')

    def validate_range(value, name='value'):
      if not check_range(value):
        range_str = ''
        if r.get('min', nan) == r.get('max', nan):
          msg = '{0} must equal {1}'.format(name, r['min'])
          raise SchemaRangeMismatch(msg)

        if 'min' in r:
          range_str = '[{0}, '.format(r['min'])
        elif 'min-ex' in r:
          range_str = '({0}, '.format(r['min-ex'])
        else:
          range_str = '(-inf, '

        if 'max' in r:
          range_str += '{0}]'.format(r['max'])
        elif 'max-ex' in r:
          range_str += '{0})'.format(r['max-ex'])
        else:
          range_str += 'inf)'

        raise SchemaRangeMismatch(name+' must be in range '+range_str)

    return validate_range


class Factory(object):
  def __init__(self, register_core_types=True):
    self.prefix_registry = {
      '':      'tag:codesimply.com,2008:rx/core/',
      '.meta': 'tag:codesimply.com,2008:rx/meta/',
    }

    self.type_registry = {}
    if register_core_types:
      for t in core_types: self.register_type(t)

  @staticmethod
  def _default_prefixes(): pass

  def expand_uri(self, type_name):
    if re.match('^\w+:', type_name): return type_name

    m = re.match('^/([-._a-z0-9]*)/([-._a-z0-9]+)$', type_name)

    if not m:
      raise ValueError("couldn't understand type name '{0}'".format(type_name))

    prefix, suffix = m.groups()

    if prefix not in self.prefix_registry:
      raise KeyError(
        "unknown prefix '{0}' in type name '{1}'".format(prefix, type_name)
      )

    return self.prefix_registry[ prefix ] + suffix

  def add_prefix(self, name, base):
    if self.prefix_registry.get(name):
      raise SchemaError("the prefix '{0}' is already registered".format(name))

    self.prefix_registry[name] = base;

  def register_type(self, t):
    t_uri = t.uri()

    if t_uri in self.type_registry:
      raise ValueError("type already registered for {0}".format(t_uri))

    self.type_registry[t_uri] = t

  def learn_type(self, uri, schema):
    if self.type_registry.get(uri):
      raise SchemaError("tried to learn type for already-registered uri {0}".format(uri))

    # make sure schema is valid
    # should this be in a try/except?
    self.make_schema(schema)

    self.type_registry[uri] = { 'schema': schema }

  def make_schema(self, schema):
    if isinstance(schema, string_types):
      schema = { 'type': schema }

    if not isinstance(schema, dict):
      raise SchemaError('invalid schema argument to make_schema')

    uri = self.expand_uri(schema['type'])

    if not self.type_registry.get(uri): raise SchemaError("unknown type {0}".format(uri))

    type_class = self.type_registry[uri]

    if isinstance(type_class, dict):
      if not {'type'}.issuperset(schema):
        raise SchemaError('composed type does not take check arguments');
      return self.make_schema(type_class['schema'])
    else:
      return type_class(schema, self)

class _CoreType(object):
  @classmethod
  def uri(self):
    return 'tag:codesimply.com,2008:rx/core/' + self.subname()

  def __init__(self, schema, rx):
    if not {'type'}.issuperset(schema):
      raise SchemaError('unknown parameter for //{0}'.format(self.subname()))

  def check(self, value):
    try:
      self.validate(value)
    except SchemaMismatch:
      return False
    return True

  def validate(self, value, name='value'):
    raise SchemaMismatch('Tried to validate abstract base schema class')

class AllType(_CoreType):
  @staticmethod
  def subname(): return 'all'

  def __init__(self, schema, rx):
    if not {'type', 'of'}.issuperset(schema):
      raise SchemaError('unknown parameter for //all')
    
    if not(schema.get('of') and len(schema.get('of'))):
      raise SchemaError('no alternatives given in //all of')

    self.alts = [rx.make_schema(s) for s in schema['of']]

  def validate(self, value, name='value'):
    error_messages = []
    for schema in self.alts:
      try:
        schema.validate(value, name)
      except SchemaMismatch as e:
        error_messages.append(str(e))

    if len(error_messages) > 1:
      messages = indent('\n'.join(error_messages))
      message = '{0} failed to meet all schema requirements:\n{1}'
      message = message.format(name, messages)
      raise SchemaMismatch(message)
    elif len(error_messages) == 1:
      raise SchemaMismatch(error_messages[0])

class AnyType(_CoreType):
  @staticmethod
  def subname(): return 'any'

  def __init__(self, schema, rx):
    self.alts = None

    if not {'type', 'of'}.issuperset(schema):
      raise SchemaError('unknown parameter for //any')
    
    if schema.get('of') is not None:
      if not schema['of']: raise SchemaError('no alternatives given in //any of')
      self.alts = [ rx.make_schema(alt) for alt in schema['of'] ]

  def validate(self, value, name='value'):
    if self.alts is None:
      return
    error_messages = []
    for schema in self.alts:
      try:
        schema.validate(value, name)
        break
      except SchemaMismatch as e:
        error_messages.append(str(e))

    if len(error_messages) == len(self.alts):
      messages = indent('\n'.join(error_messages))
      message = '{0} failed to meet any schema requirements:\n{1}'
      message = message.format(name, messages)
      raise SchemaMismatch(message)

class ArrType(_CoreType):
  @staticmethod
  def subname(): return 'arr'

  def __init__(self, schema, rx):
    self.length = None

    if not {'type', 'contents', 'length'}.issuperset(schema):
      raise SchemaError('unknown parameter for //arr')

    if not schema.get('contents'):
      raise SchemaError('no contents provided for //arr')

    self.content_schema = rx.make_schema(schema['contents'])

    if schema.get('length'):
      self.length = Util.make_range_validator(schema['length'])

  def validate(self, value, name='value'):
    if not isinstance(value, (list, tuple)):
      raise SchemaTypeMismatch(name, 'array')

    if self.length:
      self.length(len(value), name+' length')

    error_messages = []

    for i, item in enumerate(value):
      try:
        self.content_schema.validate(item, 'item '+str(i))
      except SchemaMismatch as e:
        error_messages.append(str(e))

    if len(error_messages) > 1:
      messages = indent('\n'.join(error_messages))
      message = '{0} sequence contains invalid elements:\n{1}'
      message = message.format(name, messages)
      raise SchemaMismatch(message)
    elif len(error_messages) == 1:
      raise SchemaMismatch(name+': '+error_messages[0])

class BoolType(_CoreType):
  @staticmethod
  def subname(): return 'bool'

  def validate(self, value, name='value'):
    if not (isinstance(value, bool)):
      raise SchemaTypeMismatch(name, 'boolean')

class DefType(_CoreType):
  @staticmethod
  def subname(): return 'def'


  def validate(self, value, name='value'):
    if value is None:
      raise SchemaMismatch(name+' must be non-null')

class FailType(_CoreType):
  @staticmethod
  def subname(): return 'fail'

  def check(self, value): return False

  def validate(self, value, name='value'):
    raise SchemaMismatch(name+' is of fail type, automatically invalid.')

class IntType(_CoreType):
  @staticmethod
  def subname(): return 'int'

  def __init__(self, schema, rx):
    if not {'type', 'range', 'value'}.issuperset(schema):
      raise SchemaError('unknown parameter for //int')

    self.value = None
    if 'value' in schema:
      if not isinstance(schema['value'], Number) or schema['value'] % 1 != 0:
        raise SchemaError('invalid value parameter for //int')
      self.value = schema['value']

    self.range = None
    if 'range' in schema:
      self.range = Util.make_range_validator(schema['range'])

  def validate(self, value, name='value'):
    if not isinstance(value, Number) or isinstance(value, bool) or value%1:
      raise SchemaTypeMismatch(name,'integer')

    if self.range:
      self.range(value, 'name')

    if self.value is not None and value != self.value:
      raise SchemaValueMismatch(name, self.value)

class MapType(_CoreType):
  @staticmethod
  def subname(): return 'map'

  def __init__(self, schema, rx):
    self.allowed = set()

    if not {'type', 'values'}.issuperset(schema):
      raise SchemaError('unknown parameter for //map')

    if not schema.get('values'):
      raise SchemaError('no values given for //map')

    self.value_schema = rx.make_schema(schema['values'])

  def validate(self, value, name='value'):
    if not isinstance(value, dict):
      raise SchemaTypeMismatch(name, 'map')

    error_messages = []

    for key, val in value.items():
      try:
        self.value_schema.validate(val, key)
      except SchemaMismatch as e:
        error_messages.append(str(e))

    if len(error_messages) > 1:
      messages = indent('\n'.join(error_messages))
      message = '{0} map contains invalid entries:\n{1}'
      message = message.format(name, messages)
      raise SchemaMismatch(message)
    elif len(error_messages) == 1:
      raise SchemaMismatch(name+': '+error_messages[0])

class NilType(_CoreType):
  @staticmethod
  def subname(): return 'nil'

  def check(self, value): return value is None

  def validate(self, value, name='value'):
    if value is not None:
      raise SchemaTypeMismatch(name, 'null')

class NumType(_CoreType):
  @staticmethod
  def subname(): return 'num'

  def __init__(self, schema, rx):
    if not {'type', 'range', 'value'}.issuperset(schema):
      raise SchemaError('unknown parameter for //num')

    self.value = None
    if 'value' in schema:
      if not isinstance(schema['value'], Number):
        raise SchemaError('invalid value parameter for //num')
      self.value = schema['value']

    self.range = None

    if schema.get('range'):
      self.range = Util.make_range_validator(schema['range'])

  def validate(self, value, name='value'):
    if not isinstance(value, Number) or isinstance(value, bool):
      raise SchemaTypeMismatch(name, 'number')

    if self.range:
      self.range(value, name)

    if self.value is not None and value != self.value:
      raise SchemaValueMismatch(name, self.value)

class OneType(_CoreType):
  @staticmethod
  def subname(): return 'one'

  def validate(self, value, name='value'):
    if not isinstance(value, (Number, string_types)):
      raise SchemaTypeMismatch(name, 'number or string')

class RecType(_CoreType):
  @staticmethod
  def subname(): return 'rec'

  def __init__(self, schema, rx):
    if not {'type', 'rest', 'required', 'optional'}.issuperset(schema):
      raise SchemaError('unknown parameter for //rec')

    self.known = set()
    self.rest_schema = None
    if schema.get('rest'): self.rest_schema = rx.make_schema(schema['rest'])

    for which in ('required', 'optional'):
      setattr(self, which, {})
      for field in schema.get(which, {}).keys():
        if field in self.known:
          raise SchemaError('%s appears in both required and optional' % field)

        self.known.add(field)

        self.__getattribute__(which)[field] = rx.make_schema(
          schema[which][field]
        )

  def validate(self, value, name='value'):
    if not isinstance(value, dict):
      raise SchemaTypeMismatch(name, 'record')

    unknown = [k for k in value.keys() if k not in self.known]

    if unknown and not self.rest_schema:
      fields = indent('\n'.join(unknown))
      raise SchemaMismatch(name+' contains unknown fields:\n'+fields)

    error_messages = []

    for field in self.required:
      try:
        if field not in value:
          raise SchemaMismatch('missing required field: '+field)
        self.required[field].validate(value[field], field)
      except SchemaMismatch as e:
        error_messages.append(str(e))

    for field in self.optional:
      if field not in value: continue
      try:
        self.optional[field].validate(value[field], field) 
      except SchemaMismatch as e:
        error_messages.append(str(e))

    if unknown:
      rest = {key: value[key] for key in unknown}
      try:
        self.rest_schema.validate(rest, name)
      except SchemaMismatch as e:
        error_messages.append(str(e))

    if len(error_messages) > 1:
      messages = indent('\n'.join(error_messages))
      message = '{0} record is invalid:\n{1}'
      message = message.format(name, messages)
      raise SchemaMismatch(message)
    elif len(error_messages) == 1:
      raise SchemaMismatch(name+': '+error_messages[0])


class SeqType(_CoreType):
  @staticmethod
  def subname(): return 'seq'

  def __init__(self, schema, rx):
    if not {'type', 'contents', 'tail'}.issuperset(schema):
      raise SchemaError('unknown parameter for //seq')

    if not schema.get('contents'):
      raise SchemaError('no contents provided for //seq')

    self.content_schema = [ rx.make_schema(s) for s in schema['contents'] ]

    self.tail_schema = None
    if (schema.get('tail')):
      self.tail_schema = rx.make_schema(schema['tail'])

  def validate(self, value, name='value'):
    if not isinstance(value, (list, tuple)):
      raise SchemaTypeMismatch(name, 'sequence')

    if len(value) < len(self.content_schema):
      raise SchemaMismatch(name+' is less than expected length')

    if len(value) > len(self.content_schema) and not self.tail_schema:
      raise SchemaMismatch(name+' exceeds expected length')

    error_messages = []

    for i, (schema, item) in enumerate(zip(self.content_schema, value)):
      try:
        schema.validate(item, 'item '+str(i))
      except SchemaMismatch as e:
        error_messages.append(str(e))   

    if len(error_messages) > 1:
      messages = indent('\n'.join(error_messages))
      message = '{0} sequence is invalid:\n{1}'
      message = message.format(name, messages)
      raise SchemaMismatch(message)
    elif len(error_messages) == 1:
      raise SchemaMismatch(name+': '+error_messages[0])

    if len(value) > len(self.content_schema):
      self.tail_schema.validate(value[len(self.content_schema):], name)

class StrType(_CoreType):
  @staticmethod
  def subname(): return 'str'

  def __init__(self, schema, rx):
    if not {'type', 'value', 'length'}.issuperset(schema):
      raise SchemaError('unknown parameter for //str')

    self.value = None
    if 'value' in schema:
      if not isinstance(schema['value'], string_types):
        raise SchemaError('invalid value parameter for //str')
      self.value = schema['value']

    self.length = None
    if 'length' in schema:
      self.length = Util.make_range_validator(schema['length'])

  def validate(self, value, name='value'):
    if not isinstance(value, string_types):
      raise SchemaTypeMismatch(name, 'string')
    if self.value is not None and value != self.value:
      raise SchemaValueMismatch(name, '"{0}"'.format(self.value))
    if self.length:
      self.length(len(value), name+' length')

core_types = [
  AllType,  AnyType, ArrType, BoolType, DefType,
  FailType, IntType, MapType, NilType,  NumType,
  OneType,  RecType, SeqType, StrType
]
