<?php

class Rx {
  var $registry;

  function Rx() {
    $this->registry = new stdClass();

    $core_types = Rx::core_types();

    foreach ($core_types as $str => $class_name) {
      # $auth = $class_name->authority;
      # $name = $class_name->subname;

      # if (! $this->registry->$auth)
      #   $this->registry->$auth = new stdClass();

      # $this->registry->$auth->$name = $class_name;
      $this->registry->$str = $class_name;
    }
  }

  function core_types () {
    static $core_types = array();

    if (count($core_types)) return $core_types;

    Rx::_initialize_core_types(&$core_types);
    return $core_types;
  }

  function _initialize_core_types ($ct) {
    $ct['//all']  = 'RxCoretypeAll';
    $ct['//any']  = 'RxCoretypeAny';
    $ct['//arr']  = 'RxCoretypeArr';
    $ct['//bool'] = 'RxCoretypeBool';
    $ct['//def']  = 'RxCoretypeDef';
    $ct['//int']  = 'RxCoretypeInt';
    $ct['//map']  = 'RxCoretypeMap';
    $ct['//nil']  = 'RxCoretypeNil';
    $ct['//num']  = 'RxCoretypeNum';
    $ct['//one']  = 'RxCoretypeOne';
    $ct['//rec']  = 'RxCoretypeRec';
    $ct['//seq']  = 'RxCoretypeSeq';
    $ct['//str']  = 'RxCoretypeStr';
  }

  function make_schema($schema) {
    if (! is_object($schema)) {
      $schema_name = $schema;
      $schema = new stdClass();
      $schema->type = $schema_name;
    }

    $type = $schema->type;

    if (! $type) throw new Exception("can't make a schema with no type");

    $type_class = $this->registry->$type;

    if ($type_class)
      return new $type_class($schema, $this);

    return false;
  }
}

class RxCoretypeAll {
  var $authority = '';
  var $subname   = 'all';

  var $alts;

  function check($value) {
    foreach ($this->alts as $alt) if (! $alt->check($value)) return false;
    return true;
  }

  function RxCoretypeAll($schema, $rx) {
    if (! $schema->of) {
      throw new Exception("no alternatives given for //any of");

      $this->alts = Array();
      foreach ($schema->of as $alt)
        array_push($this->alts, $rx->make_schema($alt));
    }
  }
}

class RxCoretypeAny {
  var $authority = '';
  var $subname   = 'any';

  var $alts;

  function check($value) {
    if ($this->alts == null) return true;
    foreach ($this->alts as $alt) if ($alt->check($value)) return true;
    return false;
  }

  function RxCoretypeAny($schema, $rx) {
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
  var $authority = '';
  var $subname   = 'bool';
  function check($value) { return is_bool($value); }
}

class RxCoreTypeArr {
  var $authority = '';
  var $subname   = 'arr';

  var $content_schema;
  var $length_checker;

  function _check_schema($schema) {
    foreach ($schema as $key => $entry)
      if ($key != 'contents' and $key != 'length' and $key != 'type')
        throw new Exception("unknown parameter $key for //arr schema");
  }

  function RxCoretypeArr($schema, $rx) {
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
  var $authority = '';
  var $subname   = 'num';

  var $range_checker;

  function check($value) {
    if (! (is_int($value) or is_float($value))) return false;

    if ($this->range_checker and ! $this->range_checker->check($value))
      return false;

    return true;
  }

  function _check_schema($schema, $type) {
    foreach ($schema as $key => $entry)
      if ($key != 'range' and $key != 'type')
        throw new Exception("unknown parameter $key for $type schema");
  }

  function RxCoretypeNum ($schema) {
    RxCoretypeNum::_check_schema($schema, '//num');

    if ($schema->range) {
      $this->range_checker = new RxRangeChecker( $schema->range );
    }
  }
}

class RxCoreTypeInt {
  var $authority = '';
  var $subname   = 'int';

  var $range_checker;

  function check($value) {
    if (! (is_int($value) || is_float($value))) return false;
    if (is_float($value) and $value != floor($value)) return false;
    if ($this->range_checker and ! $this->range_checker->check($value))
      return false;

    return true;
  }

  function RxCoretypeInt ($schema) {
    RxCoretypeNum::_check_schema($schema, '//int');

    if ($schema->range) {
      $this->range_checker = new RxRangeChecker( $schema->range );
    }
  }
}

class RxCoretypeDef {
  var $authority = '';
  var $subname   = 'def';
  function check($value) { return ! is_null($value); }
}

class RxCoretypeNil {
  var $authority = '';
  var $subname   = 'nil';
  function check($value) { return is_null($value); }
}

class RxCoretypeOne {
  var $authority = '';
  var $subname   = 'one';
  function check($value) { return is_scalar($value); }
}

class RxCoretypeStr {
  var $authority = '';
  var $subname   = 'str';
  function check($value) { return is_string($value); }
}

class RxCoretypeSeq {
  var $authority = '';
  var $subname   = 'seq';

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

  function RxCoretypeSeq($schema, $rx) {
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
  var $authority = '';
  var $subname   = 'map';
  
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

  function RxCoretypeMap($schema, $rx) {
    RxCoretypeMap::_check_schema($schema);

    if ($schema->values)
      $this->values_schema = $rx->make_schema($schema->values);
  }
}

class RxCoretypeRec {
  var $authority = '';
  var $subname   = 'rec';

  var $required;
  var $optional;
  var $known;
  var $rest_schema;

  function check($value) {
    if (get_class($value) != 'stdClass') return false;

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

  function RxCoretypeRec($schema, $rx) {
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

  function RxRangeChecker ($arg) {
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
