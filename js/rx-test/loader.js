var loadRxTests = (function (specRoot) {
  load('js/json_sans_eval.js');

  var indexJSON = readFile(specRoot + '/index.json');
  var index = jsonParse(indexJSON);

  var testSchema = { };
  var testData   = { };
  var totalTests = 0;

  for (i in index) {
    if (index[i] == (specRoot + '/index.json')) continue;

    var path = index[i].split('/');

    if (path.shift() != specRoot)
      throw 'invalid file in index: ' + index[i];

    fileJSON = readFile(index[i]);
    payload  = jsonParse(fileJSON);

    var fileType = path.shift();
    var leafName = path.join('/').replace(/\.json$/, '');

    if (fileType == 'data') {
      testData[ leafName ] = payload;
    } else if (fileType == 'schemata') {
      testSchema[ leafName ] = payload;
    } else {
      throw 'invalid file in index: ' + index[i]
    }
  }

  // XXX: Honestly, this is moronic.  There should be an obj.props().sort()..?
  // -- rjbs, 2008-07-30
  var schemaToTest = [];
  for (schema in testSchema) schemaToTest.push(schema);
  schemaToTest = schemaToTest.sort();
  for (i in schemaToTest) {
    var schemaName = schemaToTest[i];
    var schema = testSchema[ schemaName ];

    if (schema.invalid) {
      totalTests++;
      if (schema.pass || schema.fail)
        throw 'invalid test: ' + schemaName + ' is invalid but has pass/fail';
      continue;
    }

    var expect = { pass: [], fail: [] };

    for (pf in expect) {
      for (source in schema[pf]) {
        entries = schema[pf][source];

        if (entries instanceof Array) {
          // keep as is
        } else if (entries == '*') {
          schema[pf][source] = entries = [];
          for (entry in testData[source]) entries.push(entry);
        } else {
          throw 'invalid entry in ' + pf + ' for schemaName: ' + source;
        }

        totalTests += entries.length;
      }
    }
  }

  for (source in testData) {
    for (entry in testData[source]) {
      var jsonSnippet = testData[source][entry];
      var jsonArray = '[' + jsonSnippet + ']';
      var entryData = jsonParse(jsonArray);
      testData[source][entry] = entryData[0];
    }
  }

  return {
    totalTests: totalTests,
    testData  : testData,
    testSchema: testSchema,
  };
});
