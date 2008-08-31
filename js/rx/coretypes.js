
// I had made this a function (constructor) but there wasn't really any reason.
Rx.CoreType = {};

// Simple types

Rx.CoreType.allType = function (opt, rx) {
  if (! opt.of) throw new Rx.Error('no of given for //all');

  if (opt.of.length == 0)
    throw new Rx.Error('no alternatives given for //all of');

  this.alts = [ ];
  for (i in opt.of) this.alts.push( rx.makeSchema(opt.of[i]) )
};

Rx.CoreType.allType.uri = 'tag:codesimply.com,2008:rx/core/all';
Rx.CoreType.allType.prototype.check  = function (v) {
  for (i in this.alts) if (! this.alts[i].check(v)) return false;
  return true;
};

Rx.CoreType.anyType = function (opt, rx) {
  this.alts = null;
  if (opt.of) {
    if (opt.of.length == 0)
      throw new Rx.Error('no alternatives given for //any of');

    this.alts = [ ];
    for (i in opt.of) this.alts.push( rx.makeSchema(opt.of[i]) )
  }
};

Rx.CoreType.anyType.uri = 'tag:codesimply.com,2008:rx/core/any';
Rx.CoreType.anyType.prototype.check  = function (v) {
  if (! this.alts) return true;
  for (i in this.alts) if (this.alts[i].check(v)) return true;
  return false;
};

Rx.CoreType.boolType = function (opt) {};
Rx.CoreType.boolType.uri = 'tag:codesimply.com,2008:rx/core/bool';
Rx.CoreType.boolType.prototype.check = function (v) {
  return((typeof(v) == 'boolean') || (v instanceof Boolean));
};

Rx.CoreType.defType  = function (opt) {};
Rx.CoreType.defType.uri = 'tag:codesimply.com,2008:rx/core/def';
Rx.CoreType.defType.prototype.check  = function (v) { return v != null; };

Rx.CoreType.failType  = function (opt) {};
Rx.CoreType.failType.uri = 'tag:codesimply.com,2008:rx/core/fail';
Rx.CoreType.failType.prototype.check  = function (v) { false; };

Rx.CoreType.intType  = function (opt) {
  if (! Rx.Util._x_subset_keys_y(opt, {type: true, range: true, value: true }))
    throw new Rx.Error('unknown argument for int type');

  if (typeof(opt.value) != "undefined")
    if (opt.value.constructor != Number || opt.value % 1 != 0)
      throw new Rx.Error('invalid value parameter for int type');
    this.value = opt.value;

  if (opt.range) {
    this.range_check = new Rx.Util.RangeChecker( opt.range );
  }
};
Rx.CoreType.intType.uri = 'tag:codesimply.com,2008:rx/core/int';
Rx.CoreType.intType.prototype.check  = function (v) {
  if (v == null) return false;
  if (v.constructor != Number) return false;
  if (Math.floor(v) != v) return false;

  if (this.value != null && v != this.value) return false;
  if (this.range_check && ! this.range_check.check(v)) return false;

  return true;
};

Rx.CoreType.nilType  = function (opt) {};
Rx.CoreType.nilType.uri = 'tag:codesimply.com,2008:rx/core/nil';
Rx.CoreType.nilType.prototype.check  = function (v) { return v === null };

Rx.CoreType.numType  = function (opt) {
  if (! Rx.Util._x_subset_keys_y(opt, {type: true, range: true, value: true }))
    throw new Rx.Error('unknown argument for num type');

  if (typeof(opt.value) != "undefined")
    if (opt.value.constructor != Number)
      throw new Rx.Error('invalid value parameter for str type');
    this.value = opt.value;

  if (opt.range) {
    this.range_check = new Rx.Util.RangeChecker( opt.range );
  }
};

Rx.CoreType.numType.uri = 'tag:codesimply.com,2008:rx/core/num';
Rx.CoreType.numType.prototype.check  = function (v) {
  if (v == null) return false;
  if (v.constructor != Number) return false;
  if (this.range_check && ! this.range_check.check(v)) return false;
  if (this.value != null && v != this.value) return false;
  return true;
};

Rx.CoreType.strType  = function (opt) {
  if (! Rx.Util._x_subset_keys_y(opt, {type: true, value: true }))
    throw new Rx.Error('unknown argument for str type');
  if (typeof(opt.value) != "undefined")
    if (opt.value.constructor != String)
      throw new Rx.Error('invalid value parameter for str type');
    this.value = opt.value;
};
Rx.CoreType.strType.uri = 'tag:codesimply.com,2008:rx/core/str';
Rx.CoreType.strType.prototype.check  = function (v) {
  if (! ((typeof(v) == 'string') || (v instanceof String))) return false;
  if (this.value != null && v != this.value) return false;
  return true;
};

Rx.CoreType.oneType  = function (opt) {};
Rx.CoreType.oneType.uri = 'tag:codesimply.com,2008:rx/core/one';
Rx.CoreType.oneType.prototype.check = function (v) {
  // for some reason this was false: (false instanceof Boolean)
  if (v == null) return false;
  return (
       (v.constructor == String)
    || (v.constructor == Boolean)
    || (v.constructor == Number)
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
    this.length_check = new Rx.Util.RangeChecker( opt.length );
  }
};
Rx.CoreType.arrType.uri = 'tag:codesimply.com,2008:rx/core/arr';
Rx.CoreType.arrType.prototype.check  = function (v) {
  if (! (v instanceof Array)) return false;

  for (i in v) if (! this.content_check.check(v[i])) return false;

  if (this.length_check && ! this.length_check.check(v.length)) {
    return false;
  }

  return true;
}

Rx.CoreType.recType = function (opt, rx) {
  if (! Rx.Util._x_subset_keys_y(opt, Rx.CoreType.recType._valid_options))
    throw new Rx.Error('unknown argument for map type');

  this.known = {};

  if (opt.required) {
    this.required = {};
    for (prop in opt.required) {
      this.known[prop] = true;
      if (opt.optional && opt.optional[prop])
        throw new Rx.Error(prop + ' appears in both optional and required');
      this.required[prop] = rx.makeSchema(opt.required[prop]);
    }
  }

  if (opt.optional) {
    this.optional = {};
    for (prop in opt.optional) {
      this.known[prop] = true;
      this.optional[prop] = rx.makeSchema(opt.optional[prop]);
    }
  }

  if (opt.rest) this.restSchema = rx.makeSchema(opt.rest);
};
Rx.CoreType.recType.uri = 'tag:codesimply.com,2008:rx/core/rec';
Rx.CoreType.recType._valid_options = {
  type: true,
  rest: true,
  required: true,
  optional: true
};
Rx.CoreType.recType.prototype.check  = function (v) {
  if (!(((v != null) && (typeof(v) == 'object')) && ! (v instanceof Array)))
    return false;

  var rest = {};
  var have_rest = false;
  for (prop in v) if (! this.known[prop]) {
    have_rest = true;
    rest[ prop ] = v[ prop ];
  }
  
  if (have_rest && ! this.restSchema) return false

  for (prop in this.required) {
    if (v[prop] == null) return false;
    if (! this.required[prop].check( v[prop] ) ) return false;
  }

  for (prop in this.optional) {
    if (v[prop] == null) continue;
    if (! this.optional[prop].check( v[prop] ) ) return false;
  }

  if (have_rest && ! this.restSchema.check(rest)) return false;

  return true;
};

Rx.CoreType.mapType = function (opt, rx) {
  if (! Rx.Util._x_subset_keys_y(opt, { type: true, values: true }))
    throw new Rx.Error('unknown argument for mapall type');

  this.valueSchema = rx.makeSchema(opt.values);
};
Rx.CoreType.mapType.uri = 'tag:codesimply.com,2008:rx/core/map';
Rx.CoreType.mapType.prototype.check  = function (v) {
  if (!(((v != null) && (typeof(v) == 'object')) && ! (v instanceof Array)))
    return false;

  for (prop in v) if (! this.valueSchema.check(v[prop])) return false;

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
Rx.CoreType.seqType.uri = 'tag:codesimply.com,2008:rx/core/seq';
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

