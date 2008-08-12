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
      return new $type_class($schema);

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
  function check($value) { return RxUtil::is_seq_int_array($value); }
}

class RxCoreTypeNum {
  var $authority = '';
  var $subname   = 'num';
  function check($value) { return is_numeric($value); }
}

class RxCoreTypeInt {
  var $authority = '';
  var $subname   = 'int';
  function check($value) { return is_int($value); }
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

?>
