
// I had made this a function (constructor) but there wasn't really any reason.
Rx.CoreType = {};

// Simple types

Rx.CoreType.anyType  = function (opt) {};
Rx.CoreType.anyType.schemaName = Rx.parseTypeName('//any');
Rx.CoreType.anyType.prototype.check  = function (v) { return true; };

Rx.CoreType.boolType = function (opt) {};
Rx.CoreType.boolType.schemaName = Rx.parseTypeName('//bool');
Rx.CoreType.boolType.prototype.check = function (v) {
  return((typeof(v) == 'boolean') || (v instanceof Boolean));
};

Rx.CoreType.defType  = function (opt) {};
Rx.CoreType.defType.schemaName = Rx.parseTypeName('//def');
Rx.CoreType.defType.prototype.check  = function (v) { return v != null; };

Rx.CoreType.intType  = function (opt) {
  if (! Rx.Util._x_subset_keys_y(opt, { type: true }))
    throw new Rx.Error('unknown argument for int type');
};
Rx.CoreType.intType.schemaName = Rx.parseTypeName('//int');
Rx.CoreType.intType.prototype.check  = function (v) {
  return(
    ((typeof(v) == 'number') || (v instanceof Number)) && (Math.floor(v) == v)
  );
};

Rx.CoreType.nilType  = function (opt) {};
Rx.CoreType.nilType.schemaName = Rx.parseTypeName('//nil');
Rx.CoreType.nilType.prototype.check  = function (v) { return v === null };

Rx.CoreType.numType  = function (opt) {};
Rx.CoreType.numType.schemaName = Rx.parseTypeName('//num');
Rx.CoreType.numType.prototype.check  = function (v) {
  return((typeof(v) == 'number') || (v instanceof Number));
};

Rx.CoreType.strType  = function (opt) {};
Rx.CoreType.strType.schemaName = Rx.parseTypeName('//str');
Rx.CoreType.strType.prototype.check  = function (v) {
  return((typeof(v) == 'string') || (v instanceof String));
};

Rx.CoreType.scalarType  = function (opt) {};
Rx.CoreType.scalarType.schemaName = Rx.parseTypeName('//scalar');
Rx.CoreType.scalarType.prototype.check = function (v) {
  // for some reason this was false: (false instanceof Boolean)
  return (
    (v === null)
    || ((typeof(v) == 'string')  || (v instanceof String))
    || ((typeof(v) == 'boolean') || (v instanceof Boolean))
    || ((typeof(v) == 'number')  || (v instanceof Number))
  );
};

// Complex types

Rx.CoreType.arrType  = function (opt) {
  if (! Rx.Util._x_subset_keys_y(opt, { type: 1, contents: 1, length: 1 }))
    throw new Rx.Error('unknown argument for arr type');
  if (! opt.contents) throw new Rx.Error('no contents argument for arr type');
  if (opt.contents instanceof Array)
    throw new Rx.Error('contents arg for arr type must be a non-Array Object');
};
Rx.CoreType.arrType.schemaName = Rx.parseTypeName('//arr');
Rx.CoreType.arrType.prototype.check  = function (v) {
  return v instanceof Array;
}

Rx.CoreType.mapType  = function (opt) {
  if (! Rx.Util._x_subset_keys_y(opt, Rx.CoreType.mapType._valid_options))
    throw new Rx.Error('unknown argument for map type');
};
Rx.CoreType.mapType._valid_options =  { type: 1, required: 1, optional: 1 };
Rx.CoreType.mapType.schemaName = Rx.parseTypeName('//map');
Rx.CoreType.mapType.prototype.check  = function (v) {
  return ((v != null) && (typeof(v) == 'object'));
};

Rx.CoreType.seqType  = function (opt) {
  if (! Rx.Util._x_subset_keys_y(opt, { type: 1, contents: 1, tail: 1 }))
    throw new Rx.Error('unknown argument for seq type');
  if (! opt.contents) throw new Rx.Error('no contents argument for seq type');
  if (! (opt.contents instanceof Array))
    throw new Rx.Error('contents argument for seq type must be an Array');
};
Rx.CoreType.seqType.schemaName = Rx.parseTypeName('//seq');
Rx.CoreType.seqType.prototype.check  = function (v) {
  return v instanceof Array;
};
