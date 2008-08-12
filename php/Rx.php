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
      $schema = new stdClass();
      $schema->type = $schema;
    }

    $type = $schema->type;
    $type_class = $this->registry->$type;

    if ($type_class)
      return new $type_class($schema, $this);

    return false;
  }
}

class RxCoretypeAny {
  var $authority = '';
  var $subname   = 'any';
  function check($value) { return true; }
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

  function RxCoretypeArr($schema, $rx) {
    $this->content_schema = $rx->make_schema($schema->contents);

    if ($schema->length) {
      $this->length_checker = new RxRangeChecker(
        $schema->length,
        array(
          'allow_fractional' => false,
          'allow_exclusive'  => false,
          'allow_negative'   => false
        )
      );
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

  function RxCoretypeNum ($schema) {
    if ($schema->range) {
      $this->range_checker = new RxRangeChecker(
        $schema->range,
        array(
          'allow_fractional' => true,
          'allow_exclusive'  => true,
          'allow_negative'   => true
        )
      );
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
    if ($schema->range) {
      $this->range_checker = new RxRangeChecker(
        $schema->range,
        array(
          'allow_fractional' => false,
          'allow_exclusive'  => true,
          'allow_negative'   => true
        )
      );
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
  function check($value) { return RxUtil::is_seq_int_array($value); }
}

class RxCoretypeMap {
  var $authority = '';
  var $subname   = 'map';
  function check($value) {
    return (get_class($value) == 'stdClass');
  }
}

class RxCoretypeRec {
  var $authority = '';
  var $subname   = 'rec';
  function check($value) {
    return (get_class($value) == 'stdClass');
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

  function RxRangeChecker ($arg, $rules) {
    $valid_names = array('min', 'max');

    if ($rules['allow_exclusive'])
      array_push($valid_names, 'min-ex', 'max-ex');

    foreach ($valid_names as $name) {
      if (! property_exists($arg, $name)) continue;

      if (! $rules['allow_negative'] and $arg->$name < 0)
        throw new Exception("negative $name not allowed in range");

      if (! $rules['allow_fractional'] and ! is_int($arg->$name))
        throw new Exception("fractional $name not allowed in range");

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
