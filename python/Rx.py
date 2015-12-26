import re
from six import string_types # for 2-3 compatibility
import types
from numbers import Number

import pdb # debug only

# TODO: test the new updates to this system
# TODO: write a whole new goddamn test suite for these structured errors
core_types = [ ]

### Exception Classes --------------------------------------------------------

class SchemaError(Exception):
  pass


class SchemaMismatch(Exception):
  pass


class SchemaTypeMismatch(SchemaMismatch):
  def __init__(self, desired_type):
    vowels = 'aeiou'
    article = 'a'+'n'*(desired_type[0] in vowels)
    msg = 'must be {} {}'.format(article, desired_type)
    SchemaMismatch.__init__(self, msg)


class SchemaValueMismatch(SchemaMismatch):
  def __init__(self, value):
    SchemaMismatch.__init__(self, 'must equal {}'.format(value))


class SchemaRangeMismatch(SchemaMismatch):
  pass


class MultiSchemaMismatch(SchemaMismatch):
  def __init__(self, message = None):
    self.errors = []
    self.child_errors = {}
    self.message = message

  def __str__(self):
    error_messages = []

    for error in self.errors:
      msg = '{}'.format(error)
      error_messages.append(msg)
    for key, error in self.child_errors.items():
      # FIXME: I'm not in love with this formatting
      msg = '[{}] {}'.format(repr(key), error)
      error_messages.append(msg)

    if len(error_messages) == 1:
      return error_messages[0]
    else:
      if self.message is None:
        self.message = 'does not match schema requirements:\n'
      return self.message + Util.indent('\n'.join(error_messages))

  def __bool__(self):
    return bool(self.errors or self.child_errors)

  def __nonzero__(self):
    return self.__bool__()


### Utility Functions --------------------------------------------------------

class Util(object):
  @staticmethod
  def indent(text, level=1, whitespace='  '):
    return '\n'.join(whitespace*level+line for line in text.split('\n'))

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

    def validate_range(value, name=''):
      if not check_range(value):
        if r.get('min', nan) == r.get('max', nan):
          msg = '{} must equal {}'.format(r['min'])
          raise SchemaRangeMismatch(msg)
        
        range_str = ''
        if 'min' in r:
          range_str = '[{}, '.format(r['min'])
        elif 'min-ex' in r:
          range_str = '({}, '.format(r['min-ex'])
        else:
          range_str = '(-inf, '

        if 'max' in r:
          range_str += '{}]'.format(r['max'])
        elif 'max-ex' in r:
          range_str += '{})'.format(r['max-ex'])
        else:
          range_str += 'inf)'
        
        if name:
          name += ' ' # put a space between name and message

        raise SchemaRangeMismatch(name+'must be in range '+range_str)

    return validate_range

### Schema Factory Class -----------------------------------------------------

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
      raise ValueError("couldn't understand type name '{}'".format(type_name))

    prefix, suffix = m.groups()

    if prefix not in self.prefix_registry:
      raise KeyError(
        "unknown prefix '{0}' in type name '{}'".format(prefix, type_name)
      )

    return self.prefix_registry[ prefix ] + suffix

  def add_prefix(self, name, base):
    if self.prefix_registry.get(name):
      raise SchemaError("the prefix '{}' is already registered".format(name))

    self.prefix_registry[name] = base;

  def register_type(self, t):
    t_uri = t.uri()

    if t_uri in self.type_registry:
      raise ValueError("type already registered for {}".format(t_uri))

    self.type_registry[t_uri] = t

  def learn_type(self, uri, schema):
    if self.type_registry.get(uri):
      raise SchemaError(
        "tried to learn type for already-registered uri {}".format(uri)
        )

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

    if not self.type_registry.get(uri):
      raise SchemaError("unknown type {}".format(uri))

    type_class = self.type_registry[uri]

    if isinstance(type_class, dict):
      if not {'type'}.issuperset(schema):
        raise SchemaError('composed type does not take check arguments')
      return self.make_schema(type_class['schema'])
    else:
      return type_class(schema, self)

### Core Type Abstract Class -------------------------------------------------

class _CoreType(object):
  @classmethod
  def uri(self):
    return 'tag:codesimply.com,2008:rx/core/' + self.subname()

  def __init__(self, schema, rx):
    if not {'type'}.issuperset(schema):
      raise SchemaError('unknown parameter for //{}'.format(self.subname()))

  def check(self, value):
    try:
      self.validate(value)
    except SchemaMismatch:
      return False
    return True

  def validate(self, value):
    raise SchemaMismatch('Tried to validate abstract base schema class')

### Core Schema Types --------------------------------------------------------

class AllType(_CoreType):
  @staticmethod
  def subname(): return 'all'

  def __init__(self, schema, rx):
    if not {'type', 'of'}.issuperset(schema):
      raise SchemaError('unknown parameter for //all')
    
    if not schema.get('of'):
      raise SchemaError('no alternatives given in //all of')

    self.alts = [rx.make_schema(s) for s in schema['of']]

  def validate(self, value):
    mismatch = MultiSchemaMismatch()
    for schema in self.alts:
      try:
        schema.validate(value)
      except SchemaMismatch as e:
        mismatch.errors.append(e)

    if bool(mismatch):
      raise mismatch


class AnyType(_CoreType):
  @staticmethod
  def subname(): return 'any'

  def __init__(self, schema, rx):
    self.alts = None

    if not {'type', 'of'}.issuperset(schema):
      raise SchemaError('unknown parameter for //any')
    
    if 'of' in schema:
      if not schema['of']: 
        raise SchemaError('no alternatives given in //any of')

      self.alts = [ rx.make_schema(alt) for alt in schema['of'] ]

  def validate(self, value):
    if self.alts is None:
      return
    
    mismatch = MultiSchemaMismatch()

    for schema in self.alts:
      try:
        schema.validate(value)
        break
      except SchemaMismatch as e:
        mismatch.errors.append(e)

    if len(mismatch.errors) == len(self.alts):
      mismatch.message = "does not match any of the following:\n"
      raise mismatch


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

  def validate(self, value):
    if not isinstance(value, (list, tuple)):
      raise SchemaTypeMismatch('array')

    mismatch = MultiSchemaMismatch()

    if self.length:
      try:
        self.length(len(value), 'length')
      except SchemaRangeMismatch as e:
        mismatch.errors.append(e)

    for key, item in enumerate(value):
      try:
        self.content_schema.validate(item)
      except SchemaMismatch as e:
        mismatch.child_errors[key] = e

    if mismatch:
      raise mismatch


class BoolType(_CoreType):
  @staticmethod
  def subname(): return 'bool'

  def validate(self, value,):
    if not isinstance(value, bool):
      raise SchemaTypeMismatch('boolean')


class DefType(_CoreType):
  @staticmethod
  def subname(): return 'def'


  def validate(self, value):
    if value is None:
      raise SchemaMismatch('must be non-null')


class FailType(_CoreType):
  @staticmethod
  def subname(): return 'fail'

  def check(self, value): return False

  def validate(self, value):
    raise SchemaMismatch('is of fail type, automatically invalid.')


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

  def validate(self, value):
    if not isinstance(value, Number) or isinstance(value, bool) or value%1:
      raise SchemaTypeMismatch('integer')

    if self.range:
      self.range(value)

    if self.value is not None and value != self.value:
      raise SchemaValueMismatch(self.value)


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

  def validate(self, value):
    if not isinstance(value, dict):
      raise SchemaTypeMismatch('map')

    mismatch = MultiSchemaMismatch()

    for key, val in value.items():
      try:
        self.value_schema.validate(val)
      except SchemaMismatch as e:
        mismatch.child_errors[key] = e

    if bool(mismatch):
      raise mismatch


class NilType(_CoreType):
  @staticmethod
  def subname(): return 'nil'

  def check(self, value): return value is None

  def validate(self, value):
    if value is not None:
      raise SchemaTypeMismatch('null')


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

  def validate(self, value):
    if not isinstance(value, Number) or isinstance(value, bool):
      raise SchemaTypeMismatch('number')

    if self.range:
      self.range(value)

    if self.value is not None and value != self.value:
      raise SchemaValueMismatch(self.value)


class OneType(_CoreType):
  @staticmethod
  def subname(): return 'one'

  def validate(self, value):
    if not isinstance(value, (Number, string_types)):
      raise SchemaTypeMismatch('number or string')


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
          raise SchemaError(
            '%s appears in both required and optional' % field
            )

        self.known.add(field)

        self.__getattribute__(which)[field] = rx.make_schema(
          schema[which][field]
        )

  def validate(self, value):
    if not isinstance(value, dict):
      raise SchemaTypeMismatch('record')

    mismatch = MultiSchemaMismatch()

    for field in self.required:

      if field not in value:
        err = SchemaMismatch('missing required field: '+field)
        mismatch.errors.append(err)
      else:
        try:
          self.required[field].validate(value[field])
        except SchemaMismatch as e:
          mismatch.child_errors[field] = e

    for field in self.optional:
      if field not in value: continue

      try:
        self.optional[field].validate(value[field]) 
      except SchemaMismatch as e:
        mismatch.child_errors[field] = e

    unknown = [k for k in value.keys() if k not in self.known]

    if unknown:
      if self.rest_schema:
        rest = {key: value[key] for key in unknown}
        try:
          self.rest_schema.validate(rest)
        except SchemaMismatch as e:
          mismatch.errors.append(e)
      else:
        fields = Util.indent('\n'.join(unknown))
        error = SchemaMismatch('contains unknown fields:\n'+fields)
        mismatch.errors.append(error)
      
    if bool(mismatch):
      raise mismatch


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

  def validate(self, value):
    if not isinstance(value, (list, tuple)):
      raise SchemaTypeMismatch('sequence')

    mismatch = MultiSchemaMismatch()

    if len(value) > len(self.content_schema):
      if self.tail_schema:
        try:
          self.tail_schema.validate(value[len(self.content_schema):])
        except SchemaMismatch as e:
          mismatch.errors.append(e)  
      else:
        mismatch.errors.append(SchemaMismatch('exceeds expected length'))

    if len(value) < len(self.content_schema):
      mismatch.errors.append(SchemaMismatch('less than expected length'))

    for index, (schema, item) in enumerate(zip(self.content_schema, value)):
      try:
        schema.validate(item)
      except SchemaMismatch as e:
        mismatch.child_errors[index] = e

    if bool(mismatch):
      raise mismatch;


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

  def validate(self, value):
    if not isinstance(value, string_types):
      raise SchemaTypeMismatch('string')
    if self.value is not None and value != self.value:
      raise SchemaValueMismatch(repr(self.value))
    if self.length:
      self.length(len(value), 'length')

core_types = [
  AllType,  AnyType, ArrType, BoolType, DefType,
  FailType, IntType, MapType, NilType,  NumType,
  OneType,  RecType, SeqType, StrType
]
