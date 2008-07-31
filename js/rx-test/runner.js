load('js/rx-test/loader.js');

var plan = loadRxTests('spec');

function Rx () {
  this.make_checker = function (schema) {
    return function (value) {
      return false;
    };
  };
}

print('1..' + plan.totalTests);
var currentTest = 1;

var rx = new Rx();
var schemaToTest = [];
for (schemaName in plan.testSchema) schemaToTest.push(schemaName);
schemaToTest = schemaToTest.sort();
for (i in schemaToTest) {
  var schemaName = schemaToTest[i];
  var schemaTest = plan.testSchema[ schemaName ];

  if (schemaTest.invalid) {
    print('not ok ' + currentTest++ + ' - BAD SCHEMA: ' + schemaName);
    continue;
  }

  var rxChecker = rx.make_checker(schemaTest);

  for (pf in { pass: 1, fail: 1 }) {
    for (sourceName in schemaTest[pf]) {
      var sourceTests = schemaTest[pf][sourceName];
      var sourceData  = plan.testData[sourceName];

      for (j in sourceTests) {
        var sourceEntry = sourceTests[j];
        var testData = sourceData[ sourceEntry ];

        var valid  = rxChecker( testData );
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

