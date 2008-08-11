#!/usr/bin/php
<?php
require 'Test.php';
require 'Rx.php';

$index_json = file_get_contents('spec/index.json');
$index = json_decode($index_json);

$test_data = array();
$test_schemata = array();

foreach ($index as $file) {
  if ($file == 'spec/index.json') continue;
  $parts = explode('/', $file);
  
  array_shift($parts);
  $type = array_shift($parts);

  $leaf = $parts[ count($parts) - 1 ];
  $leaf = preg_replace('/\.json$/', '', $leaf);

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

$Rx = new Rx();

asort($test_schemata);
foreach ($test_schemata as $schema_name => $test) {
  $schema = null;

  try {
    $schema = $Rx->make_schema($test->schema);
  } catch (Exception $e) {
    if ($test->invalid) {
      pass("BAD SCHEMA: $schema_name");
      continue;
    } else {
      throw $e;
    }
  }

  if ($test->invalid) {
    fail("BAD SCHEMA: $schema_name");
    continue;
  }

  diag("testing $schema_name");
  if (! $schema) die("did not get thinger");

  foreach (array('pass', 'fail') as $pf) {
    $expect = ($pf == 'pass') ? 'VALID  ' : 'INVALID';
    if ($test->$pf == null) continue;
    foreach ($test->$pf as $source => $which) {
      if (is_string(which) and ($which == "*")) {
        $which = array();
        foreach ($test_data[$source] as $name => $x) array_push($which, $name);
      }

      foreach ($which as $entry) {
        # diag(">> " . var_dump($test_data[$source]->$entry));
        $result = $schema->check($test_data[$source]->$entry);
        if ($pf == 'fail') $result = ! $result;
        ok($result, "$expect: $source/$entry against $schema_name");
      }
    }
  }
  #foreach 
}

?>
