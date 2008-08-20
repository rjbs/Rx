
import re
import types

core_types = [ ]

class Util(object):
  @staticmethod
  def parse_type_name(type_name):
    m = re.match('^/([-._a-z0-9]*)/([-._a-z0-9]+)$', type_name)

    return {
      "authority": m.group(1),
      "subname"  : m.group(2),
    }

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

  def make_checker(self, schema):
    if not(type(schema) is type({})):
      schema = { "type": schema }
  
    sn = Util.parse_type_name(schema["type"])

    if not self.registry.has_key(sn["authority"]):
      raise "unknown authority in type %s" % schema["type"]

    if not self.registry[ sn["authority"] ].has_key(sn["subname"]):
      raise "unknown subname in type %s" % schema["type"]

    type_class = self.registry[ sn["authority"] ][ sn["subname"] ]

    return type_class(schema, self)

class Error(Exception):
  pass

class _CoreType(object):
  @staticmethod
  def authority(): return ''

  def __init__(self, schema, rx): pass

  def check(self, value): return False

class AnyType(_CoreType):
  @staticmethod
  def subname(): return 'any'

  def check(self, value): return True

class ArrType(_CoreType):
  @staticmethod
  def subname(): return 'arr'

  def check(self, value):
    if not(type(value) in [ type([]), type(()) ]): return False
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

class IntType(_CoreType):
  @staticmethod
  def subname(): return 'int'

  def check(self, value):
    if not(type(value) in (float, int, long)): return False
    if value % 1 != 0: return False
    return True

class MapType(_CoreType):
  @staticmethod
  def subname(): return 'map'

  def check(self, value):
    if not(type(value) is type({})): return False
    return True;

class NilType(_CoreType):
  @staticmethod
  def subname(): return 'nil'

  def check(self, value): return value is None

class NumType(_CoreType):
  @staticmethod
  def subname(): return 'num'

  def check(self, value):
    if not(type(value) in (float, int, long)): return False
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

  def check(self, value):
    if not(type(value) is type({})): return False
    return True;

class SeqType(_CoreType):
  @staticmethod
  def subname(): return 'seq'

  def check(self, value):
    if not(type(value) in [ type([]), type(()) ]): return False
    return True;

class StrType(_CoreType):
  @staticmethod
  def subname(): return 'str'

  def check(self, value):
    return type(value) in (str, unicode)

core_types = [
  AnyType, ArrType, BoolType, DefType,
  IntType, MapType, NilType,  NumType,
  OneType, RecType, SeqType,  StrType
]
