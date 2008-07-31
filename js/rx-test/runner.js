load('js/rx-testloader.js');

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

  for (
}

