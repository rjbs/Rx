
load('js/ext/Test.Simple/Test/Builder.js');
load('js/ext/Test.Simple/Test/More.js');

load('js/rx/test/loader.js');

load('js/rx.js');
load('js/rx/coretypes.js');

var rxPlan = loadRxTests('spec');

plan({ tests: rxPlan.totalTests });

var rx = new Rx({ defaultTypes: true });

for (coreType in Rx.CoreType)
  rx.registerType( Rx.CoreType[coreType] );

var schemaToTest = [];
for (schemaName in rxPlan.testSchema) schemaToTest.push(schemaName);
schemaToTest = schemaToTest.sort();

for (i in schemaToTest) {
  var schemaName = schemaToTest[i];
  var schemaTest = rxPlan.testSchema[ schemaName ];

  var rxChecker;

  try {
    rxChecker = rx.makeSchema(schemaTest.schema);
  } catch (e) {
    if (schemaTest.invalid && (e instanceof Rx.Error)) {
      pass('BAD SCHEMA: ' + schemaName);
      continue;
    }

    diag("exception when creating schema " + schemaName + ": " + e.message);
    throw e;
  }

  if (schemaTest.invalid) {
    fail('BAD SCHEMA: ' + schemaName);
    continue;
  }

  for (pf in { pass: 1, fail: 1 }) {
    for (sourceName in schemaTest[pf]) {
      var sourceTests = schemaTest[pf][sourceName];
      var sourceData  = rxPlan.testData[sourceName];

      for (sourceEntry in sourceTests) {
        var testData = sourceData[ sourceEntry ];

        var valid  = rxChecker.check( testData );
        var expect = pf == 'pass';

        var testDesc = (expect ? 'VALID  : ' : 'INVALID: ')
                     + sourceName + '/' + sourceEntry
                     + ' against ' + schemaName;
        
        // JavaScript needs logical xor! -- rjbs, 2008-07-31
        if ((valid && !expect) || (!valid && expect)) {
          fail(testDesc);
        } else {
          pass(testDesc);
        }
      }
    }
  }
}

