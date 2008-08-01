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

