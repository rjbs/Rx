
function Rx (opt) {
  this.authority = { };

  if (opt.defaultTypes) {
    this.authority[''] = {
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
  }
}

Rx.CoreType = function () { throw 'you cannot make a Rx.CoreType directly' };

Rx.CoreType.anyType  = function (opt) {};
Rx.CoreType.arrType  = function (opt) {};
Rx.CoreType.boolType = function (opt) {};
Rx.CoreType.defType  = function (opt) {};
Rx.CoreType.intType  = function (opt) {};
Rx.CoreType.mapType  = function (opt) {};
Rx.CoreType.nilType  = function (opt) {};
Rx.CoreType.numType  = function (opt) {};
Rx.CoreType.seqType  = function (opt) {};
Rx.CoreType.strType  = function (opt) {};

Rx.CoreType.scalarType  = function (opt) {};

Rx.CoreType.anyType.prototype.check  = function (v) { return true; };
Rx.CoreType.arrType.prototype.check  = function (v) { return v instanceof Array; };
Rx.CoreType.boolType.prototype.check = function (v) { return v instanceof Boolean; };
Rx.CoreType.defType.prototype.check  = function (v) { return v != null; };
Rx.CoreType.intType.prototype.check  = function (v) {
  return((v instanceof Number) && (Math.floor(v) == v));
};
Rx.CoreType.mapType.prototype.check  = function (v) { return typeof(v) == 'object';};
Rx.CoreType.nilType.prototype.check  = function (v) { return v === null };
Rx.CoreType.numType.prototype.check  = function (v) { return v instanceof Number; };
Rx.CoreType.scalarType.prototype.check = function (v) {
  return
    (v instanceof String) || (v instanceof Boolean) || (v instanceof Number);
};
Rx.CoreType.seqType.prototype.check  = function (v) { return v instanceof Array; };
Rx.CoreType.strType.prototype.check  = function (v) { return v instanceof String; };

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
  var typeChecker = this._checkerFor(schema.type);

  return new typeChecker(schema);
};
