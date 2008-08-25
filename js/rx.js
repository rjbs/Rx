function Rx (opt) {
  this.authority = { };
}

Rx.parseTypeName = function (name) {
  var matches = name.match(/^\/(\w*)\/(\w+)$/);

  if (! matches) throw 'invalid type name: ' + name;

  return {
    authorityName: matches[1],
    subName      : matches[2]
  };
}

Rx.prototype.registerType = function (type, opt) {
  var sn = type.typeName;
  var auth = this.authority[ sn.authorityName ];

  if (! auth) auth = this.authority[ sn.authorityName ] = {};
  if (auth[ sn.subName ]) throw 'registration already present';
  auth[ sn.subName ] = type;
};

Rx.prototype.typeFor = function (typeName) {
  var sn = Rx.parseTypeName(typeName);

  var auth = this.authority[sn.authorityName];
  if (!auth) throw 'unknown authority in: ' + typeName;

  var typeChecker = auth[sn.subName];
  if (! typeChecker) throw 'unknown datatype in: ' + typeName;

  return typeChecker;
};

Rx.prototype.makeSchema = function (schema) {
  if (schema.constructor == String) schema = { type: schema };
  var typeChecker = this.typeFor(schema.type);
  return new typeChecker(schema, this);
};

Rx.Error = function (message) { this.message = message };

Rx.Util = {};

Rx.Util._x_subset_keys_y = function (x, y) {
  var x_props = [];
  var y_props = [];

  for (i in x) x_props.push(x[i]);
  for (i in y) y_props.push(y[i]);

  if (x.length > y.length) return false;
  for (i in x) if (y[ i ] === undefined) return false;
  return true;
};

{
  var validOptions = { min: true, 'min-ex': true, max: true, 'max-ex': true };

  Rx.Util.RangeChecker = function (opt) {
    if (! Rx.Util._x_subset_keys_y(opt, validOptions))
      throw new Rx.Error('unknown options for RangeChecker');

    var minEx = opt['min-ex'];
    var maxEx = opt['max-ex'];
    var min   = opt['min'];
    var max   = opt['max'];

    this.check = function (value) {
      if ((minEx != null) && (value <= minEx)) return false 
      if ((min   != null) && (value <  min  )) return false 
      if ((max   != null) && (value >  max  )) return false 
      if ((maxEx != null) && (value >= maxEx)) return false 
      return true;
    };
  };
}
