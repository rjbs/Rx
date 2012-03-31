var loadRxTests = (function (specRoot) {
  load('js/ext/json_sans_eval.js');

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

  for (source in testData) {
    if (testData[source] instanceof Array) {
      var newData = { };
      for (i in testData[source])
        newData[ testData[source][i] ] = testData[source][i];
      testData[source] = newData;
    }
    for (entry in testData[source]) {
      var jsonSnippet = testData[source][entry];
      var jsonArray = '[' + jsonSnippet + ']';
      var entryData = jsonParse(jsonArray);
      testData[source][entry] = entryData[0];
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

    if (schema['composed-type'])
      continue;

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
          entriesObj = { };

          for (i in entries) entriesObj[ entries[i] ] = null;

          entries = entriesObj;
        }

        if (entries == '*') entries = { '*': null };

        if (entries instanceof Object) {
          if (entries.hasOwnProperty('*')) {
            value = entries['*'];
            delete entries['*'];

            for (entry in testData[source]) {
              entries[entry] = value;
            }
          }

          for (prop in entries) totalTests++;

          schema[pf][source] = entries;
          continue;
        };

        throw 'invalid entry in ' + pf + ' for schemaName: ' + source;
      }
    }
  }

  return {
    totalTests: totalTests,
    testData  : testData,
    testSchema: testSchema,
  };
});
