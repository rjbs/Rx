function Rx (opt) {
  this.type_registry   = { };
  this.prefix_registry = {
    '':      'tag:codesimply.com,2008:rx/core/',
    '.meta': 'tag:codesimply.com,2008:rx/meta/'
  };
}

Rx.prototype.expand_uri = function (name) {
  if (name.match(/^\w+:/)) return name;

  var matches = name.match(/^\/(\w*)\/(\w+)$/);

  if (! matches)
    throw new Rx.Error("couldn't understand type name '" + name + "'");

  if (! this.prefix_registry[ matches[1] ])
    throw new Rx.Error("unknown prefix '" + matches[1] + "' in type name '" + name + "'");

  return this.prefix_registry[ matches[1] ] + matches[2];
}

Rx.prototype.addPrefix = function (name, base) {
  if (this.prefix_registry[ name ])
      throw new Rx.Error("the prefix '" + name + "' is already registered");

  this.prefix_registry[ name ] = base;
}

Rx.prototype.registerType = function (type, opt) {
  var uri = type.uri;

  if (this.type_registry[ uri ])
    throw new Rx.Error("tried to register type for already-registered uri " + uri);

  this.type_registry[ uri ] = type;
};

Rx.prototype.learnType = function (uri, schema) {
  if (this.type_registry[ uri ])
    throw new Rx.Error("tried to learn type for already-registered uri " + uri);

  // make sure schema is valid
  // should this be in a try/catch?
  this.makeSchema(schema);

  this.type_registry[ uri ] = { schema: schema };
};

Rx.prototype.typeFor = function (typeName) {
  var uri = this.expand_uri(typeName);

  var typeChecker = this.type_registry[ uri ];
  if (! typeChecker) throw new Rx.Error('unknown type: ' + uri);

  return typeChecker;
};

Rx.prototype.makeSchema = function (schema) {
  if (schema.constructor == String) schema = { type: schema };
  var typeChecker = this.typeFor(schema.type);

  if (typeof(typeChecker) == 'object') {
    if (! Rx.Util._x_subset_keys_y(schema, { type: true }))
      throw new Rx.Error('composed type does not take check arguments');
    return this.makeSchema(typeChecker.schema);
  } else {
    return new typeChecker(schema, this);
  }
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
