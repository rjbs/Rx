load('js/rx/test/loader.js');

var plan = loadRxTests('spec');

print('1..' + plan.totalTests);
var currentTest = 1;

load('js/rx.js');
load('js/rx/coretypes.js');

var schemaToTest = [];
for (schemaName in plan.testSchema) schemaToTest.push(schemaName);
schemaToTest = schemaToTest.sort();
for (i in schemaToTest) {
  var rx = new Rx({ defaultTypes: true });

  for (coreType in Rx.CoreType) rx.registerType( Rx.CoreType[coreType] );

  var schemaName = schemaToTest[i];
  var schemaTest = plan.testSchema[ schemaName ];

  if (schemaTest['composed-type']) {
    try {
      rx.learnType(schemaTest['composed-type'].uri,
                   schemaTest['composed-type'].schema);
    } catch (e) {
      if (schemaTest['composed-type'].invalid && (e instanceof Rx.Error)) {
        print('ok ' + currentTest++ + ' - BAD COMPOSED TYPE: ' + schemaName);
        continue;
      }
      print("# exception thrown when learning type " + schemaName + ": " + e.message);
      throw e;
    }

    if (schemaTest['composed-type'].invalid) {
      print('not ok ' + currentTest++ + ' - BAD COMPOSED TYPE: ' + schemaName);
      continue;
    }

    if (schemaTest['composed-type'].prefix) {
      rx.addPrefix(schemaTest['composed-type'].prefix[0],
                   schemaTest['composed-type'].prefix[1]);
    }
  }

  var rxChecker;

  try {
    rxChecker = rx.makeSchema(schemaTest.schema);
  } catch (e) {
    if (schemaTest.invalid && (e instanceof Rx.Error)) {
      print('ok ' + currentTest++ + ' - BAD SCHEMA: ' + schemaName);
      continue;
    }
    print("# exception thrown when creating schema " + schemaName + ": " + e.message);
    throw e;
  }

  if (schemaTest.invalid) {
    print('not ok ' + currentTest++ + ' - BAD SCHEMA: ' + schemaName);
    continue;
  }

  for (pf in { pass: 1, fail: 1 }) {
    for (sourceName in schemaTest[pf]) {
      var sourceTests = schemaTest[pf][sourceName];
      var sourceData  = plan.testData[sourceName];

      for (j in sourceTests) {
        var sourceEntry = sourceTests[j];
        var testData = sourceData[ sourceEntry ];

        var valid  = rxChecker.check( testData );
        var expect = pf == 'pass';

        var testDesc = (expect ? 'VALID  : ' : 'INVALID: ')
                     + sourceName + '/' + sourceEntry
                     + ' against ' + schemaName;
        
        // JavaScript needs logical xor! -- rjbs, 2008-07-31
        if ((valid && !expect) || (!valid && expect)) {
          print("not ok " + currentTest++ + ' - ' + testDesc);
        } else {
          print("ok " + currentTest++ + ' - ' + testDesc);
        }
      }
    }
  }
}

