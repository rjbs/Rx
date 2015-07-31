from TAP.Simple import *
import Rx
import json
import re
import pdb
import os

plan(None)
os.chdir('..')
rx = Rx.Factory({ "register_core_types": True });

isa_ok(rx, Rx.Factory)

index = json.loads(open('spec/index.json').read())

test_data     = {}
test_schemata = {}

def normalize(entries, test_data):
  if entries == '*':
    entries = { "*": None }

  if type(entries) is type([]):
    new_entries = { }
    for n in entries: new_entries[n] = None
    entries = new_entries

  if len(entries) == 1 and '*' in entries:
    value = entries["*"]
    entries = { }
    for k in test_data.keys(): entries[k] = value

  return entries

for filename in index:
  if filename == 'spec/index.json': continue
  payload = json.loads(open(filename).read())

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
        boxed_data = json.loads("[ %s ]" % data_str)
        test_data[ leaf_name ][ data_str ] = boxed_data[0]

    else:
      for entry in payload.keys():
        boxed_data = json.loads("[ %s ]" % payload[entry])
        test_data[ leaf_name ][ entry ] = boxed_data[0]
  else:
    raise StandardError("weird file in data dir: %s" % filename)

schema_names = list(sorted(test_schemata.keys()))

for schema_name in schema_names:
  rx = Rx.Factory({ "register_core_types": True });

  schema_test_spec = test_schemata[ schema_name ]

  if schema_test_spec.get("composedtype", False):
    try:
      rx.learn_type(schema_test_spec['composedtype']['uri'],
                    schema_test_spec['composedtype']['schema'])
    except Rx.SchemaError as e:
      if schema_test_spec['composedtype'].get("invalid", False):
        ok(1, "BAD COMPOSED TYPE: schemata %s" % schema_name)
        continue
      else:
        raise

    if schema_test_spec['composedtype'].get("invalid", False):
      ok(0, "BAD COMPOSED TYPE: schemata %s" % schema_name)

    if schema_test_spec['composedtype'].get("prefix", False):
       rx.add_prefix(schema_test_spec['composedtype']['prefix'][0],
                     schema_test_spec['composedtype']['prefix'][1])

  try:
    schema = rx.make_schema(schema_test_spec["schema"])
  except Rx.SchemaError as e:
    #pdb.set_trace()
    if schema_test_spec.get("invalid", False):
      ok(1, "BAD SCHEMA: schemata %s" % schema_name)
      continue
    else:
      raise

  if schema_test_spec.get("invalid", False):
    ok(0, "BAD SCHEMA: schemata %s" % schema_name)
    continue

  if not schema: raise StandardError("got no schema obj for valid input")

  for pf in [ 'pass', 'fail' ]:
    for source in schema_test_spec.get(pf, []):
      to_test = schema_test_spec[pf][ source ]

      to_test = normalize(to_test, test_data[ source ])
      # if to_test == '*': to_test = test_data[ source ].keys()

      for entry in to_test:
        result = None
        try:
          schema.validate(test_data[source][entry])
          result = True
        except Rx.SchemaMismatch as e:
          print(str(e))
          result = False

        desc = "%s/%s against %s" % (source, entry, schema_name)

        if pf == 'pass':
          ok(result, "VALID  : %s" % desc)
          #if not result:
          #  pdb.set_trace()
          #  result = schema.check( test_data[source][entry] )
        else:
          ok(not result, "INVALID: %s" % desc)
          #if result:
          #  pdb.set_trace()
          #  result = schema.check( test_data[source][entry] )
