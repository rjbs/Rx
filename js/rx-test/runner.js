load('js/rx-test/loader.js');

var plan = loadRxTests('spec');

print('1..' + plan.totalTests);
var currentTest = 1;

load('js/rx.js');
var rx = new Rx({});
rx.authority[''] = {
  any   : Rx.CoreType.anyType,
  arr   : Rx.CoreType.arrType,
  bool  : Rx.CoreType.boolType,
  def   : Rx.CoreType.defType,
  'int' : Rx.CoreType.intType,
  map   : Rx.CoreType.mapType,
  nil   : Rx.CoreType.nilType,
  num   : Rx.CoreType.numType,
  seq   : Rx.CoreType.seqType,
  str   : Rx.CoreType.strType,
  scalar: Rx.CoreType.scalarType,
};

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

  var rxChecker = rx.make_checker(schemaTest.schema);

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

