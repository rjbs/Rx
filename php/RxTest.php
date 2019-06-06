#!/usr/bin/php
<?php
include_once("vendor/autoload.php");

require 'ext/Test.php';

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
      $new_v->$entry = $entry;
    }

    $test_data[$k] = $v = $new_v;
  }

  foreach ($test_data[$k] as $entry => $json) {
    $j_arr = json_decode("[ $json ]");
    $test_data[$k]->$entry = $j_arr[0];
    # diag("loaded $json ($k/$entry) as " . var_export($j_arr[0], true));
  }
}

function normalize($entries, $test_data) {
  if ($entries == '*') {
    $entries = new stdClass();
    $key = "*";
    $entries->$key = null;
  }

  if (is_array($entries)) {
    $new_entries = new stdClass();
    foreach ($entries as $entry) {
      $new_entries->$entry = $entry;
    }

    $entries = $new_entries;
  }

  if (count((array) $entries) == 1 and property_exists($entries, "*")) {
    $key  = "*";
    $value = $entries->$key;
    $new_entries = new stdClass();
    foreach ($test_data as $name => $entry) {
      $new_entries->$name = $entry;
    }
    $entries = $new_entries;
  }

  return $entries;
}

function test_json($x, $y) {
  return false;
}

asort($test_schemata);
foreach ($test_schemata as $schema_name => $test) {
  if (isset($_ENV["RX_TEST_SCHEMA"]) and $_ENV["RX_TEST_SCHEMA"] != $schema_name)
    continue;

  $Rx = new Rx\Rx();

  $schema = null;

  if (isset($test->composedtype)) {
    try {
      $Rx->learnType($test->composedtype->uri, $test->composedtype->schema);
    } catch (Exception $e) {
      if (isset($test->composedtype->invalid)) {
        pass("BAD COMPOSED TYPE: $schema_name");
        continue;
      } else {
        throw $e;
      }
    }

    if (isset($test->composedtype->invalid)) {
      fail("BAD COMPOSED TYPE: $schema_name");
      continue;
    }

    if (isset($test->composedtype->prefix))
      $Rx->addPrefix($test->composedtype->prefix[0],
                      $test->composedtype->prefix[1]);
  }

  try {
    $schema = $Rx->makeSchema($test->schema);
  } catch (Exception $e) {
    if (isset($test->invalid)) {
      pass("BAD SCHEMA: $schema_name");
      continue;
    } else {
      throw $e;
    }
  }

  if (isset($test->invalid)) {
    fail("BAD SCHEMA: $schema_name");
    continue;
  }

  if (! $schema) die("did not get schema for valid input");

  foreach (array('pass', 'fail') as $pf) {
    $expect = ($pf == 'pass') ? 'VALID  ' : 'INVALID';
    if (!isset($test->$pf)) continue;

    foreach ($test->$pf as $source => $entries) {
      $entries = normalize($entries, $test_data[$source]);

      foreach ($entries as $name => $want) {
        $value = $test_data[$source]->$name;

        $result = $schema->check($value);
        if ($pf == 'fail') $result = ! $result;

        if ("$source/$entry" == "num/0e0")
          todo_start("PHP's json_decode can't handle 0e0 as number");

        ok($result, "$expect: $source/$name against $schema_name");

        if ("$source/$entry" == "num/0e0")
          todo_end();
      }
    }
  }
}

?>
