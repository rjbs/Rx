import re
from six import string_types # for 2-3 compatibility
import types
from numbers import Number

import pdb # for debugging only

### Exception Classes --------------------------------------------------------

class SchemaError(Exception):
  pass

class SchemaMismatch(Exception):

  def __init__(self, message, schema, error=None):
    Exception.__init__(self, message)
    self.type = schema.subname() 
    self.error = error

class TypeMismatch(SchemaMismatch):
  
  def __init__(self, schema, data):
    message = 'must be of type {} (was {})'.format(
      schema.subname(),
      type(data).__name__
      )

    SchemaMismatch.__init__(self, message, schema, 'type')
    self.expected_type = schema.subname()
    self.value = type(data).__name__


class ValueMismatch(SchemaMismatch):
  
  def __init__(self, schema, data):

    message = 'must equal {} (was {})'.format(
      repr(schema.value),
      repr(data)
      )

    SchemaMismatch.__init__(self, message, schema, 'value')
    self.expected_value = schema.value
    self.value = data

 

class RangeMismatch(SchemaMismatch):
  
  def __init__(self, schema, data):
    
    message = 'must be in range {} (was {})'.format(
      schema.range,
      data
      )

    SchemaMismatch.__init__(self, message, schema, 'range')
    self.range = schema.range
    self.value = data


class LengthRangeMismatch(SchemaMismatch):

  def __init__(self, schema, data):
    length_range = Range(schema.length)

    if not hasattr(length_range, 'min') and \
       not hasattr(length_range, 'min_ex'):
      length_range.min = 0

    message = 'length must be in range {} (was {})'.format(
      length_range,
      len(data)
      )

    SchemaMismatch.__init__(self, message, schema, 'range')
    self.range = schema.length
    self.value = len(data)


class MissingFieldMismatch(SchemaMismatch):

  def __init__(self, schema, fields):

    if len(fields) == 1:
      message = 'missing required field: {}'.format(
        repr(fields[0])
        )
    else:
      message = 'missing required fields: {}'.format(
        ', '.join(fields)
        )
      if len(message) >= 80: # if the line is too long
        message = 'missing required fields:\n{}'.format(
          _indent('\n'.join(fields))
          )

    SchemaMismatch.__init__(self, message, schema, 'missing')
    self.fields = fields


class UnknownFieldMismatch(SchemaMismatch):

  def __init__(self, schema, fields):

    if len(fields) == 1:
      message = 'unknown field: {}'.format(
        repr(fields[0])
        )
    else:
      message = 'unknown fields: {}'.format(
        ', '.join(fields)
        )
      if len(message) >= 80: # if the line is too long
        message = 'unknown fields:\n{}'.format(
          _indent('\n'.join(fields))
          )

    SchemaMismatch.__init__(self, message, schema, 'unexpected')
    self.fields = fields


class SeqLengthMismatch(SchemaMismatch):
  def __init__(self, schema, data):

    expected_length = len(schema.content_schema)
    message = 'sequence must have {} element{} (had {})'.format(
      expected_length,
      's'*(expected_length != 1), # plural
      len(data)
      )

    SchemaMismatch.__init__(self, message, schema, 'size')
    self.expected_length = expected_length
    self.value = len(data)


class TreeMismatch(SchemaMismatch):

  def __init__(self, schema, errors=[], child_errors={}, message=None):
    
    ## Create error message

    error_messages = []

    for err in errors:
      error_messages.append(str(err))

    for key, err in child_errors.items():

      if isinstance(key, int):
        index = '[item {}]'.format(key)
      else:
        index = '{}'.format(repr(key))

      if isinstance(err, TreeMismatch) and \
          not err.errors and len(err.child_errors) == 1:

        template = '{} > {}'

      else:
        template = '{} {}'

      msg = template.format(index, err)
      error_messages.append(msg)

    if message is None:
      message = 'does not match schema'

    if len(error_messages) == 1:
      msg = error_messages[0]

    else:
      msg = '{}:\n{}'.format(
        message,
        _indent('\n'.join(error_messages))
        )

    SchemaMismatch.__init__(self, msg, schema, 'multiple')
    self.errors = errors
    self.child_errors = child_errors

def _createTreeMismatch(schema, errors=[], child_errors={}, message=None):
  if len(errors) == 1 and not child_errors:
    return errors[0]
  else:
    return TreeMismatch(schema, errors, child_errors, message)

### Utilities ----------------------------------------------------------------

class Range(object):

  def __init__(self, opt):
    if isinstance(opt, Range):
      for attr in ('min', 'max', 'min_ex', 'max_ex'):
        if hasattr(opt, attr):
          setattr(self, attr, getattr(opt, attr))
    else:
      if not {'min', 'max', 'min-ex', 'max-ex'}.issuperset(opt):
        raise ValueError("illegal argument to make_range_check")
      if {'min', 'min-ex'}.issubset(opt):
        raise ValueError("Cannot define both exclusive and inclusive min")
      if {'max', 'max-ex'}.issubset(opt):
        raise ValueError("Cannot define both exclusive and inclusive max")

      for boundary in ('min', 'max', 'min-ex', 'max-ex'):
        if boundary in opt:
          attr = boundary.replace('-', '_')
          setattr(self, attr, opt[boundary])

  def __call__(self, value):
    INF = float('inf')

    get = lambda attr, default: getattr(self, attr, default)

    return(
        get('min',    -INF) <= value and \
        get('max',     INF) >= value and \
        get('min_ex', -INF) <  value and \
        get('max_ex',  INF) >  value
        )

  def __str__(self):
    if hasattr(self, 'min'):
      s = '[{}, '.format(self.min)
    elif hasattr(self, 'min_ex'):
      s = '({}, '.format(self.min_ex)
    else:
      s = '(-Inf, '

    if hasattr(self, 'max'):
      s += '{}]'.format(self.max)
    elif hasattr(self, 'max_ex'):
      s += '{})'.format(self.max_ex)
    else:
      s += 'Inf)'
    
    return s

def _indent(text, level=1, whitespace='  '):
    return '\n'.join(whitespace*level+line for line in text.split('\n'))

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

std_factory = None
def make_schema(schema):
  global std_factory
  if std_factory is None:
    std_factory = Factory()
  return std_factory.make_schema(schema)

### Core Type Base Class -------------------------------------------------

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
    raise SchemaMismatch('Tried to validate abstract base schema class', self)

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
    errors = []
    for schema in self.alts:
      try:
        schema.validate(value)
      except SchemaMismatch as e:
        errors.append(e)

    if errors:
      raise _createTreeMismatch(self, errors)


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
    
    errors = []

    for schema in self.alts:
      try:
        schema.validate(value)
        break
      except SchemaMismatch as e:
        errors.append(e)

    if len(errors) == len(self.alts):
      message = 'must satisfy at least one of the following'
      raise _createTreeMismatch(self, errors, message=message)


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
      self.length = Range(schema['length'])

  def validate(self, value):
    if not isinstance(value, (list, tuple)):
      raise TypeMismatch(self, value)

    errors = []
    if self.length and not self.length(len(value)):
      err = LengthRangeMismatch(self, value)
      errors.append(err)

    child_errors = {}

    for key, item in enumerate(value):
      try:
        self.content_schema.validate(item)
      except SchemaMismatch as e:
        child_errors[key] = e
    if errors or child_errors:
      raise _createTreeMismatch(self, errors, child_errors)


class BoolType(_CoreType):
  @staticmethod
  def subname(): return 'bool'

  def validate(self, value,):
    if not isinstance(value, bool):
      raise TypeMismatch(self, value)


class DefType(_CoreType):
  @staticmethod
  def subname(): return 'def'

  def validate(self, value):
    if value is None:
      raise TypeMismatch(self, value)


class FailType(_CoreType):
  @staticmethod
  def subname(): return 'fail'

  def check(self, value): return False

  def validate(self, value):
    raise SchemaMismatch(
      'is of fail type, automatically invalid.',
      self,
      'fail'
      )


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
      self.range = Range(schema['range'])

  def validate(self, value):
    if not isinstance(value, Number) or isinstance(value, bool) or value%1:
      raise TypeMismatch(self, value)

    if self.range and not self.range(value):
      raise RangeMismatch(self, value)

    if self.value is not None and value != self.value:
      raise ValueMismatch(self, value)


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
      raise TypeMismatch(self, value)

    child_errors = {}

    for key, val in value.items():
      try:
        self.value_schema.validate(val)
      except SchemaMismatch as e:
        child_errors[key] = e

    if child_errors:
      raise _createTreeMismatch(self, child_errors=child_errors)


class NilType(_CoreType):
  @staticmethod
  def subname(): return 'nil'

  def check(self, value): return value is None

  def validate(self, value):
    if value is not None:
      raise TypeMismatch(self, value)


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
      self.range = Range(schema['range'])

  def validate(self, value):
    if not isinstance(value, Number) or isinstance(value, bool):
      raise TypeMismatch(self, value)

    if self.range and not self.range(value):
      raise RangeMismatch(self, value)

    if self.value is not None and value != self.value:
      raise ValueMismatch(self, value)


class OneType(_CoreType):
  @staticmethod
  def subname(): return 'one'

  def validate(self, value):
    if not isinstance(value, (Number, string_types)):
      raise TypeMismatch(self, value)


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
      raise TypeMismatch(self, value)

    errors = []
    child_errors = {}

    missing_fields = []

    for field in self.required:

      if field not in value:
        missing_fields.append(field)
      else:
        try:
          self.required[field].validate(value[field])
        except SchemaMismatch as e:
          child_errors[field] = e

    if missing_fields:
      err = MissingFieldMismatch(self, missing_fields)
      errors.append(err)

    for field in self.optional:
      if field not in value: continue

      try:
        self.optional[field].validate(value[field]) 
      except SchemaMismatch as e:
        child_errors[field] = e

    unknown = [k for k in value.keys() if k not in self.known]

    if unknown:
      if self.rest_schema:
        rest = {key: value[key] for key in unknown}
        try:
          self.rest_schema.validate(rest)
        except SchemaMismatch as e:
          errors.append(e)
      else:
        fields = _indent('\n'.join(unknown))
        err = UnknownFieldMismatch(self, unknown)
        errors.append(err)
    
    if errors or child_errors:
      raise _createTreeMismatch(self, errors, child_errors)


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
      raise TypeMismatch(self, value)

    errors = []

    if len(value) != len(self.content_schema):
      if len(value) > len(self.content_schema) and self.tail_schema:
        try:
          self.tail_schema.validate(value[len(self.content_schema):])
        except SchemaMismatch as e:
          errors.append(e)
      else:
        err = SeqLengthMismatch(self, value)
        errors.append(err)

    child_errors = {}

    for index, (schema, item) in enumerate(zip(self.content_schema, value)):
      try:
        schema.validate(item)
      except SchemaMismatch as e:
        child_errors[index] = e

    if errors or child_errors:
      raise _createTreeMismatch(self, errors, child_errors)


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
      self.length = Range(schema['length'])

  def validate(self, value):
    if not isinstance(value, string_types):
      raise TypeMismatch(self, value)

    if self.value is not None and value != self.value:
      raise ValueMismatch(self, self)

    if self.length and not self.length(len(value)):
      raise LengthRangeMismatch(self, value)

core_types = [
  AllType,  AnyType, ArrType, BoolType, DefType,
  FailType, IntType, MapType, NilType,  NumType,
  OneType,  RecType, SeqType, StrType
]
