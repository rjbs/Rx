
// I had made this a function (constructor) but there wasn't really any reason.
Rx.CoreType = {};

// Simple types

Rx.CoreType.anyType  = function (opt) {};
Rx.CoreType.anyType.typeName = Rx.parseTypeName('//any');
Rx.CoreType.anyType.prototype.check  = function (v) { return true; };

Rx.CoreType.boolType = function (opt) {};
Rx.CoreType.boolType.typeName = Rx.parseTypeName('//bool');
Rx.CoreType.boolType.prototype.check = function (v) {
  return((typeof(v) == 'boolean') || (v instanceof Boolean));
};

Rx.CoreType.defType  = function (opt) {};
Rx.CoreType.defType.typeName = Rx.parseTypeName('//def');
Rx.CoreType.defType.prototype.check  = function (v) { return v != null; };

Rx.CoreType.intType  = function (opt) {
  if (! Rx.Util._x_subset_keys_y(opt, { type: true }))
    throw new Rx.Error('unknown argument for int type');
};
Rx.CoreType.intType.typeName = Rx.parseTypeName('//int');
Rx.CoreType.intType.prototype.check  = function (v) {
  return(
    ((typeof(v) == 'number') || (v instanceof Number)) && (Math.floor(v) == v)
  );
};

Rx.CoreType.nilType  = function (opt) {};
Rx.CoreType.nilType.typeName = Rx.parseTypeName('//nil');
Rx.CoreType.nilType.prototype.check  = function (v) { return v === null };

Rx.CoreType.numType  = function (opt) {};
Rx.CoreType.numType.typeName = Rx.parseTypeName('//num');
Rx.CoreType.numType.prototype.check  = function (v) {
  return((typeof(v) == 'number') || (v instanceof Number));
};

Rx.CoreType.strType  = function (opt) {};
Rx.CoreType.strType.typeName = Rx.parseTypeName('//str');
Rx.CoreType.strType.prototype.check  = function (v) {
  return((typeof(v) == 'string') || (v instanceof String));
};

Rx.CoreType.scalarType  = function (opt) {};
Rx.CoreType.scalarType.typeName = Rx.parseTypeName('//scalar');
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

Rx.CoreType.arrType  = function (opt, rx) {
  if (! Rx.Util._x_subset_keys_y(opt, { type: 1, contents: 1, length: 1 }))
    throw new Rx.Error('unknown argument for arr type');
  if (! opt.contents) throw new Rx.Error('no contents argument for arr type');
  if ((opt.contents.constructor != String) && (! opt.contents.type))
    throw new Rx.Error('contents arg for arr type must declare a type');

  this.content_check = rx.makeSchema(opt.contents);
  if (opt.length) {
    this.length_check = new Rx.Util.RangeChecker(
      { allowNegative: false, allowFraction: false, allowExclusive: false },
      opt.length
    );
  }
};
Rx.CoreType.arrType.typeName = Rx.parseTypeName('//arr');
Rx.CoreType.arrType.prototype.check  = function (v) {
  if (! (v instanceof Array)) return false;

  for (i in v) if (! this.content_check.check(v[i])) return false;

  if (this.length_check && ! this.length_check.check(v.length)) {
    return false;
  }

  return true;
}

Rx.CoreType.mapType = function (opt, rx) {
  if (! Rx.Util._x_subset_keys_y(opt, Rx.CoreType.mapType._valid_options))
    throw new Rx.Error('unknown argument for map type');

  this.allowed = {};

  if (opt.required) {
    this.required = {};
    for (prop in opt.required) {
      this.allowed[prop] = true;
      if (opt.optional && opt.optional[prop])
        throw new Rx.Error(prop + ' appears in both optional and required');
      this.required[prop] = rx.makeSchema(opt.required[prop]);
    }
  }

  if (opt.optional) {
    this.optional = {};
    for (prop in opt.optional) {
      this.allowed[prop] = true;
      this.optional[prop] = rx.makeSchema(opt.optional[prop]);
    }
  }
};
Rx.CoreType.mapType._valid_options =  { type: 1, required: 1, optional: 1 };
Rx.CoreType.mapType.typeName = Rx.parseTypeName('//map');
Rx.CoreType.mapType.prototype.check  = function (v) {
  if (!(((v != null) && (typeof(v) == 'object')) && ! (v instanceof Array)))
    return false;

  for (prop in v) if (! this.allowed[prop]) return false;

  for (prop in this.required) {
    if (v[prop] == null) return false;
    if (! this.required[prop].check( v[prop] ) ) return false;
  }

  for (prop in this.optional) {
    if (v[prop] == null) continue;
    if (! this.optional[prop].check( v[prop] ) ) return false;
  }

  return true;
};

Rx.CoreType.seqType  = function (opt, rx) {
  if (! Rx.Util._x_subset_keys_y(opt, { type: 1, contents: 1, tail: 1 }))
    throw new Rx.Error('unknown argument for seq type');
  if (! opt.contents) throw new Rx.Error('no contents argument for seq type');
  if (! (opt.contents instanceof Array))
    throw new Rx.Error('contents argument for seq type must be an Array');

  this.content_checks = [];
  for (i in opt.contents)
    this.content_checks[i] = rx.makeSchema(opt.contents[i]);

  if (opt.tail) {
    this.tail_check = rx.makeSchema(opt.tail);
  }
};
Rx.CoreType.seqType.typeName = Rx.parseTypeName('//seq');
Rx.CoreType.seqType.prototype.check  = function (v) {
  if (!(v instanceof Array)) return false;

  if (v.length < this.content_checks.length) return false;

  if (v.length > this.content_checks.length) {
    if (this.tail_check) {
      var tail = v.slice(this.content_checks.length, v.length);
      if (! this.tail_check.check( tail )) return false;
    } else {
      return false;
    }
  }

  for (i in this.content_checks)
    if (! this.content_checks[i].check(v[i])) return false;

  return true;
};
