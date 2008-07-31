
function Rx (options) {
  this.authority = { };
}

Rx.CoreType = { 
  intType: function () {},
};

Rx.parseTypeName = function (name) {
  var matches = name.match(/^\/(\w*)\/(\w+)$/);

  if (! matches) throw 'invalid type name: ' + name;

  return {
    authorityName: matches[1],
    dataTypeName : matches[2],
  };
}

Rx.prototype._checkerFor = function (schemaType) {
  var sn = Rx.parseTypeName(schemaType);

  var auth = this.authority[sn.authorityName];
  if (!auth) throw 'unknown authority in: ' + schemaType;

  var typeChecker = auth[sn.dataTypeName];
  if (! typeChecker) throw 'unknown datatype in: ' + schemaType;

  return typeChecker;
};

Rx.prototype.make_checker = function (schema) {
  var checkerMaker = this._checkerFor(schema.type);

  checkerMaker.checkerFor(schema);
};
