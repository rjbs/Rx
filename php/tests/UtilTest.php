#!/usr/bin/php
<?php
include_once("vendor/autoload.php");

require 'tests/Test.php';

$testArrays = array(
  'foobarbaz' => array('foo', 'bar', 'baz'),
  'noelems'   => array()
);

foreach ($testArrays as $name => $value) {
  ok(
    Rx\Util::isSeqIntArray($value),
    "test array $name is a seq_int_array"
  );
}

$test_nonarrays = array(
  'nonseq' => array(1 => 'start-at-one', 'two', 'three'),
  'nonint' => array('key' => 'value')
);

foreach ($test_nonarrays as $name => $value) {
  ok(
    ! Rx\Util::isSeqIntArray($value),
    "test array $name is not a seq_int_array"
  );
}


?>
