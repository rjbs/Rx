
load('js/json_sans_eval.js');
var spec_root = 'spec';
var indexJSON = readFile(spec_root + '/index.json');
var index = jsonParse(indexJSON);

var test_schema = { };
var test_data   = { };

for (i in index) {
  if (index[i] == (spec_root + '/index.json')) continue;

  var path = index[i].split('/');

  if (path.shift() != spec_root)
    throw 'invalid file in index: ' + index[i];

  fileJSON = readFile(index[i]);
  payload  = jsonParse(fileJSON);

  var fileType = path.shift();
  var leafName = path.join('/').replace(/\.json$/, '');

  if (fileType == 'data') {
    test_data[ leafName ] = payload;
  } else if (fileType == 'schemata') {
    test_schema[ leafName ] = payload;
  } else {
    throw 'invalid file in index: ' + index[i]
  }
}

// XXX: Honestly, this is moronic.  There should be an obj.props().sort()..?
// -- rjbs, 2008-07-30
var schema_to_test = [];
for (schema in test_schema) schema_to_test.push(schema);
for (i in schema_to_test.sort()) {
  var schema_name = schema_to_test[i];
  var schema = test_schema[ schema_name ];
  print("now going to test " + schema_name + "...");

  if (schema.invalid) {
    print("...expecting BAD SCHEMA");
    continue;
  }

  var expect = { pass: [], fail: [] };

  for (pf in expect) {
    for (source in schema[pf]) {
      print(pf + ' for ' + source);
      entries = schema[pf][source];

      if (entries instanceof Array) {
        // keep as is
      } else if (entries == '*') {
        entries = [];
        for (entry in test_data[source]) entries.push(entry);
      } else {
        throw 'invalid entry in ' + pf + ' for schema_name: ' + source;
      }

      for (i in entries)
        print('...expected ' + pf + ' for ' + source + '/' + entries[i]);
    }
  }
}
