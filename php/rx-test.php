#!/usr/bin/php
<?php
require 'Test.php';
plan(1);

$index_json = file_get_contents('spec/index.json');
$index = json_decode($index_json);

$test_data = array();
$test_schemata = array();

# $x = json_decode('{"foo":1}');
foreach ($index as $file) {
  if ($file == 'spec/index.json') continue;
  $parts = explode('/', $file);
  
  array_shift($parts);
  $type = array_shift($parts);

  $leaf = $parts[ count($parts) - 1 ];
  preg_replace('/\.json$/', '', $leaf);

  if ($type == 'schemata') {
    $file = join("/", $parts);
    $test_schemata[ $leaf ] = json_decode(
      file_get_contents("spec/schemata/$file")
    );
  } else if ($type == 'data') {
    $file = join("/", $parts);
    $test_data[ $leaf ] = json_decode(
      file_get_contents("spec/data/$file")
    );
  } else {
    die("unknown entries in index.json");
  }
}

foreach ($test_data as $k => $v) {
  if (is_array($v)) {
    $new_v = new stdClass();

    foreach ($v as $entry) {
      $v_arr = json_decode("[ $entry ]");
      $new_v->$entry = $v_arr[0];
    }

    $test_data[$k] = $v = $new_v;
  }

  foreach ($test_data[$k] as $entry => $json) {
    $j_arr = json_decode("[ $json ]");
    $test_data[$k]->$entry = $j_arr[0];
  }
}

function test_json($x, $y) {
  return false;
}

ok(1, 'this is a test test');

foreach ($test_schemata as $schema_name => $test) {
  if ($test->invalid) {
    ok(0, "BAD SCHEMA: $schema_name");
    continue;
  }

  foreach (array('pass', 'fail') as $pf) {
    $expect = ($pf == 'pass') ? 'VALID  ' : 'INVALID';

    foreach ($test->$pf as $source => $which) {
      if (is_string(which) and ($which== "*")) {
        $which = array();
        foreach ($test_data[$source] as $e) array_push($which, $e);
      }

      foreach ($which as $entry) {
        ok(0, "testing $source/$entry against $schema_name");
      }
    }
  }
  #foreach 
}

?>
