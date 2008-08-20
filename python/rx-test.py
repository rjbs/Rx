from TAP.Simple import *
import Rx
import cjson
import re

plan(None)

ok(1, "Let's get this party started.")

rx = Rx.Factory({ "register_core_types": True });

isa_ok(rx, Rx.Factory)

index = cjson.decode(file('spec/index.json').read())

test_data     = {}
test_schemata = {}

for filename in index:
  if filename == 'spec/index.json': continue
  payload = cjson.decode(file(filename).read())

  parts = filename.split('/')
  parts.pop(0)

  leaf_name = '/'.join(parts[1:])
  leaf_name = re.sub('\.json$', '', leaf_name)
  
  filetype = parts.pop(0)

  if filetype == 'schemata':
    test_schemata[ leaf_name ] = payload
  elif filetype == 'data':
    test_data[ leaf_name ] = {}

    if type(payload) is type([]):
      for data_str in payload:
        boxed_data = cjson.decode("[ %s ]" % data_str)
        test_data[ leaf_name ][ data_str ] = boxed_data[0]

    else:
      for entry in payload.keys():
        boxed_data = cjson.decode("[ %s ]" % payload[entry])
        test_data[ leaf_name ][ entry ] = boxed_data[0]
  else:
    raise "weird file in data dir: %s" % filename

schema_names = test_schemata.keys()
schema_names.sort()

for schema_name in schema_names:
  schema_test_spec = test_schemata[ schema_name ]

  try:
    schema = rx.make_checker(schema_test_spec["schema"])
  except Rx.Error, e:
    diag("got an Rx.Error")
    if schema_test_spec.get("invalid", False):
      ok(1, "BAD SCHEMA: schemata %s" % schema_name)
    else:
      raise

  if schema_test_spec.get("invalid", False):
    ok(0, "BAD SCHEMA: schemata %s" % schema_name)

  if not schema: raise "got no schema obj for valid input"

  for pf in [ 'pass', 'fail' ]:
    for source in schema_test_spec.get(pf, []):
      to_test = schema_test_spec[pf][ source ]

      if to_test == '*': to_test = test_data[ source ].keys()

      for entry in to_test:
        result = schema.check( test_data[source][entry] )

        desc = "%s/%s against %s" % (source, entry, schema_name)

        if pf == 'pass':
          ok(result, "VALID  : %s" % desc)
        else:
          ok(not(result), "INVALID: %s" % desc)
