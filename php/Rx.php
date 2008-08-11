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
    $ct['//num']  = 'RxCoretypeNum';
    $ct['//int']  = 'RxCoretypeInt';
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
  function check($value) { return is_array($value); }
}

class RxCoreTypeNum {
  var $authority = '';
  var $subname   = 'arr';
  function check($value) { return is_numeric($value); }
}

class RxCoreTypeInt {
  var $authority = '';
  var $subname   = 'arr';
  function check($value) { return is_int($value); }
}
  
# int
# map
# num
# one
# rec
# seq
# str

class RxCoretypeDef {
  function check($value) { return ! is_null($value); }
}

class RxCoretypeNil {
  function check($value) { return is_null($value); }
}

?>
