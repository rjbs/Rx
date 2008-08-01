function Rx (opt) {
  this.authority = { };
}

Rx.prototype.registerType = function (type, opt) {
  var sn = type.schemaName;
  var auth = this.authority[ sn.authorityName ];

  if (! auth) auth = this.authority[ sn.authorityName ] = {};
  if (auth[ sn.dataTypeName ]) throw 'registration already present';
  auth[ sn.dataTypeName ] = type;
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
  var typeChecker = this._checkerFor(schema.type);

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
  // My JavaScript is lousy; I need something like obj.hasProp(name) -- rjbs,
  // 2008-07-31
  for (i in x) if (! y[ i ]) return false;
  return true;
};

{
var validOptions = { min:1, 'min-ex':1, max:1, 'max-ex':1 };

var validRules = {
  allowNegative:1,
  allowFraction:1,
  allowExclusive:1,
};

Rx.Util.RangeChecker = function (rule, opt) {
  if (! Rx.Util._x_subset_keys_y(opt, validOptions))
    throw new Rx.Error('unknown options for RangeChecker');

  if (! Rx.Util._x_subset_keys_y(rule, validRules))
    throw new Rx.Error('unknown rules for RangeChecker');

  if (
    (!rule.allowExclusive)
    && ((opt['min-ex'] != null) || (opt['max-ex'] != null))
  ) {
    throw new Rx.Error('exclusive endpoints not allowed');
  }

  for (prop in validOptions) {
    if (opt[prop] == null) continue;

    if ((!rule.allowNegative) && (opt[prop] < 0))
      throw new Rx.Error('negative endpoints not allowed');

    if ((!rule.allowFractional) && (opt[prop] != Math.floor(opt[prop])))
      throw new Rx.Error('fractional endpoints not allowed');
  }

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
