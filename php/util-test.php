#!/usr/bin/php
<?php
require 'Test.php';
require 'Rx.php';

$test_arrays = array(
  'foobarbaz' => array('foo', 'bar', 'baz'),
  'noelems'   => array()
);

foreach ($test_arrays as $name => $value) {
  ok(
    RxUtil::is_seq_int_array($value),
    "test array $name is a seq_int_array"
  );
}

$test_nonarrays = array(
  'nonseq' => array(1 => 'start-at-one', 'two', 'three'),
  'nonint' => array('key' => 'value')
);

foreach ($test_nonarrays as $name => $value) {
  ok(
    ! RxUtil::is_seq_int_array($value),
    "test array $name is not a seq_int_array"
  );
}


?>
