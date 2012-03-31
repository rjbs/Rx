<?php

class Rx {
  var $type_registry;
  var $prefix_registry;

  function __construct() {
    $this->type_registry = new stdClass();
    $this->prefix_registry = array(
      ''      => 'tag:codesimply.com,2008:rx/core/',
      '.meta' => 'tag:codesimply.com,2008:rx/meta/',
    );

    $core_types = Rx::core_types();

    foreach ($core_types as $class_name) {
      $uri = eval("return $class_name::uri;");
      $this->type_registry->$uri = $class_name;
    }
  }

  function expand_uri($name) {
    if (preg_match('/^\w+:/', $name)) return $name;

    if (preg_match('/^\\/(.*?)\\/(.+)$/', $name, $matches)) {
      if (! array_key_exists($matches[1], $this->prefix_registry)) {
        throw new Exception("unknown type prefix '$matches[1]' in '$name'");
      }

      $uri = $this->prefix_registry[ $matches[1] ] . $matches[2];
      return $uri;
    }

    throw new Exception("couldn't understand type name $name");
  }

  function core_types () {
    static $core_types = array();;

    if (count($core_types)) return $core_types;

    $core_types = array(
      'RxCoretypeAll',
      'RxCoretypeAny',
      'RxCoretypeArr',
      'RxCoretypeBool',
      'RxCoretypeDef',
      'RxCoretypeFail',
      'RxCoretypeInt',
      'RxCoretypeMap',
      'RxCoretypeNil',
      'RxCoretypeNum',
      'RxCoretypeOne',
      'RxCoretypeRec',
      'RxCoretypeSeq',
      'RxCoretypeStr',
    );

    return $core_types;
  }

  function make_schema($schema) {
    if (! is_object($schema)) {
      $schema_name = $schema;
      $schema = new stdClass();
      $schema->type = $schema_name;
    }

    $type = $schema->type;

    if (! $type) throw new Exception("can't make a schema with no type");

    $uri = $this->expand_uri($type);

    $type_class = $this->type_registry->$uri;
  
    if ($type_class)
      return new $type_class($schema, $this);

    return false;
  }
}

class RxCoretypeAll {
  const uri = 'tag:codesimply.com,2008:rx/core/all';

  var $alts;

  function check($value) {
    foreach ($this->alts as $alt) if (! $alt->check($value)) return false;
    return true;
  }

  function __construct($schema, $rx) {
    if (! $schema->of)
      throw new Exception("no alternatives given for //all of");

    $this->alts = Array();
    foreach ($schema->of as $alt)
      array_push($this->alts, $rx->make_schema($alt));
  }
}

class RxCoretypeAny {
  const uri = 'tag:codesimply.com,2008:rx/core/any';

  var $alts;

  function check($value) {
    if ($this->alts == null) return true;
    foreach ($this->alts as $alt) if ($alt->check($value)) return true;
    return false;
  }

  function __construct($schema, $rx) {
    if ($schema->of !== null) {
      if (count($schema->of) == 0)
        throw new Exception("no alternatives given for //any of");

      $this->alts = Array();
      foreach ($schema->of as $alt)
        array_push($this->alts, $rx->make_schema($alt));
    }
  }
}

class RxCoretypeBool {
  const uri = 'tag:codesimply.com,2008:rx/core/bool';
  function check($value) { return is_bool($value); }
}

class RxCoreTypeArr {
  const uri = 'tag:codesimply.com,2008:rx/core/arr';

  var $content_schema;
  var $length_checker;

  function _check_schema($schema) {
    foreach ($schema as $key => $entry)
      if ($key != 'contents' and $key != 'length' and $key != 'type')
        throw new Exception("unknown parameter $key for //arr schema");
  }

  function __construct($schema, $rx) {
    RxCoretypeArr::_check_schema($schema);

    if (! $schema->contents)
      throw new Exception('no contents entry for //arr schema');

    $this->content_schema = $rx->make_schema($schema->contents);

    if ($schema->length) {
      $this->length_checker = new RxRangeChecker( $schema->length );
    }
  }

  function check($value) {
    if (! RxUtil::is_seq_int_array($value)) return false;

    if ($this->length_checker)
      if (! $this->length_checker->check(count($value))) return false;

    foreach ($value as $i => $entry) {
      if (! $this->content_schema->check($entry)) return false;
    }

    return true;
  }
}

class RxCoreTypeNum {
  const uri = 'tag:codesimply.com,2008:rx/core/num';

  var $range_checker;
  var $fixed_value;

  function check($value) {
    if (! (is_int($value) or is_float($value))) return false;

    if ($this->fixed_value !== null) {
      if ($value != $this->fixed_value)
      return false;
    }

    if ($this->range_checker and ! $this->range_checker->check($value))
      return false;

    return true;
  }

  function _check_schema($schema, $type) {
    foreach ($schema as $key => $entry)
      if ($key != 'range' and $key != 'type' and $key != 'value')
        throw new Exception("unknown parameter $key for $type schema");
  }

  function __construct ($schema) {
    RxCoretypeNum::_check_schema($schema, '//num');

    if ($schema->value !== null) {
      if (! (is_int($schema->value) || is_float($schema->value)))
        throw new Exception('invalid value for //num schema');

      $this->fixed_value = $schema->value;
    }

    if ($schema->range) {
      $this->range_checker = new RxRangeChecker( $schema->range );
    }
  }
}

class RxCoreTypeInt {
  const uri = 'tag:codesimply.com,2008:rx/core/int';

  var $range_checker;
  var $fixed_value;

  function check($value) {
    if (! (is_int($value) || is_float($value))) return false;
    if (is_float($value) and $value != floor($value)) return false;

    if ($this->fixed_value !== null) {
      if ($value != $this->fixed_value)
      return false;
    }

    if ($this->range_checker and ! $this->range_checker->check($value))
      return false;

    return true;
  }

  function __construct ($schema) {
    RxCoretypeNum::_check_schema($schema, '//int');

    if ($schema->value !== null) {
      if (! (is_int($schema->value) || is_float($schema->value)))
        throw new Exception('invalid value for //int schema');

      if (is_float($schema->value) and $schema->value != floor($schema->value))
        throw new Exception('invalid value for //int schema');

      $this->fixed_value = $schema->value;
    }

    if ($schema->range) {
      $this->range_checker = new RxRangeChecker( $schema->range );
    }
  }
}

class RxCoretypeDef {
  const uri = 'tag:codesimply.com,2008:rx/core/def';
  function check($value) { return ! is_null($value); }
}

class RxCoretypeFail {
  const uri = 'tag:codesimply.com,2008:rx/core/fail';
  function check($value) { return false; }
}

class RxCoretypeNil {
  const uri = 'tag:codesimply.com,2008:rx/core/nil';
  function check($value) { return is_null($value); }
}

class RxCoretypeOne {
  const uri = 'tag:codesimply.com,2008:rx/core/one';
  function check($value) { return is_scalar($value); }
}

class RxCoretypeStr {
  const uri = 'tag:codesimply.com,2008:rx/core/str';
  var $fixed_value;
  var $length_checker;

  function check($value) {
    if (! is_string($value)) return false;
    if ($this->fixed_value !== null and $value != $this->fixed_value)
      return false;

    if ($this->length_checker)
      if (! $this->length_checker->check(strlen($value))) return false;

    return true;
  }

  function __construct($schema, $rx) {
    if ($schema->value !== null) {
      if (! is_string($schema->value))
        throw new Exception('invalid value for //str schema');

      $this->fixed_value = $schema->value;
    }

    if ($schema->length) {
      $this->length_checker = new RxRangeChecker( $schema->length );
    }
  }
}

class RxCoretypeSeq {
  const uri = 'tag:codesimply.com,2008:rx/core/seq';

  var $content_schemata;
  var $tail_schema;

  function check($value) {
    if (! RxUtil::is_seq_int_array($value)) return false;
  
    foreach ($this->content_schemata as $i => $schema) {
      if (! array_key_exists($i, $value)) return false;
      if (! $schema->check($value[$i])) return false;
    }

    if (count($value) > count($this->content_schemata)) {
      if (! $this->tail_schema) return false;

      $tail = array_slice(
        $value,
        count($this->content_schemata),
        count($value) - count($this->content_schemata)
      );

      if (! $this->tail_schema->check($tail)) return false;
    }

    return true;
  }

  function __construct($schema, $rx) {
    if (! $schema->contents)
      throw new Exception('no contents entry for //seq schema');
  
    if (! is_array($schema->contents))
      throw new Exception('contents entry for //seq schema is not an array');

    $this->content_schemata = array();

    foreach ($schema->contents as $i => $entry) {
      array_push($this->content_schemata, $rx->make_schema($entry));
    }

    if ($schema->tail) $this->tail_schema = $rx->make_schema($schema->tail);
  }
}

class RxCoretypeMap {
  const uri = 'tag:codesimply.com,2008:rx/core/map';
  
  var $values_schema;

  function check($value) {
    if (get_class($value) != 'stdClass') return false;

    if ($this->values_schema) {
      foreach ($value as $key => $entry) {
        if (! $this->values_schema->check($entry)) return false;
      }
    }

    return true;
  }

  function _check_schema($schema) {
    foreach ($schema as $key => $entry)
      if ($key != 'values' and $key != 'type')
        throw new Exception("unknown parameter $key for //map schema");
  }

  function __construct($schema, $rx) {
    RxCoretypeMap::_check_schema($schema);

    if ($schema->values)
      $this->values_schema = $rx->make_schema($schema->values);
  }
}

class RxCoretypeRec {
  const uri = 'tag:codesimply.com,2008:rx/core/rec';

  var $required;
  var $optional;
  var $known;
  var $rest_schema;

  function check($value) {
    if (! is_object($value) or get_class($value) != 'stdClass') return false;

    $rest = new stdClass();
    $have_rest = false;

    foreach ($value as $key => $entry) {
      if (! $this->known->$key) {
        $have_rest = true;
        $rest->$key = $entry;
      }
    }

    if ($have_rest and ! $this->rest_schema) return false;

    foreach ($this->required as $key => $schema) {
      if (! property_exists($value, $key)) return false;
      if (! $schema->check($value->$key)) return false;
    }

    foreach ($this->optional as $key => $schema) {
      if (! property_exists($value, $key)) continue;
      if (! $schema->check($value->$key)) return false;
    }

    if ($have_rest and ! $this->rest_schema->check($rest)) return false;

    return true;
  }

  function _check_schema($schema) {
    foreach ($schema as $key => $entry)
      if ($key != 'optional' and $key != 'required' and $key != 'rest' and $key != 'type')
        throw new Exception("unknown parameter $key for //rec schema");
  }

  function __construct($schema, $rx) {
    RxCoretypeRec::_check_schema($schema);

    $this->known  = new stdClass();
    $this->required = new stdClass();
    $this->optional = new stdClass();

    if ($schema->rest) $this->rest_schema = $rx->make_schema($schema->rest);

    if ($schema->required) {
      foreach ($schema->required as $key => $entry) {
        $this->known->$key = true;
        $this->required->$key = $rx->make_schema($entry);
      }
    }

    if ($schema->optional) {
      foreach ($schema->optional as $key => $entry) {
        if ($this->known->$key)
          throw new Exception("$key is both required and optional in //map");

        $this->known->$key = true;
        $this->optional->$key = $rx->make_schema($entry);
      }
    }
  }
}

class RxUtil {
  function is_seq_int_array($value) {
    if (! is_array($value)) return false;

    for ($i = 0; $i < count($value); $i++)
      if (! array_key_exists($i, $value)) return false;

    return true;
  }
}

class RxRangeChecker {
  var $min;
  var $min_ex;
  var $max_ex;
  var $max;

  function __construct ($arg) {
    $valid_names = array('min', 'max', 'min-ex', 'max-ex');

    foreach ($valid_names as $name) {
      if (! property_exists($arg, $name)) continue;

      $prop_name = preg_replace('/-/', '_', $name);
      $this->$prop_name = $arg->$name;
    }
  }

  function check($value) {
    if (! is_null($this->min)    and $value <  $this->min   ) return false;
    if (! is_null($this->min_ex) and $value <= $this->min_ex) return false;
    if (! is_null($this->max_ex) and $value >= $this->max_ex) return false;
    if (! is_null($this->max)    and $value >  $this->max   ) return false;

    return true;
  }
}

?>
