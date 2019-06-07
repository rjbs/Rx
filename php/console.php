<?php
declare(strict_types=1);

include_once("vendor/autoload.php");

use Symfony\Component\Yaml\Yaml;

if (! isset($argv[1]) || ! isset($argv[2]) || ! file_exists($argv[1]) || ! file_exists($argv[2])) {
    echo "  ❌  Unable to find file(s) in argument(s).\n";
    die();
}
try {
    $schemaFile = Yaml::parse(file_get_contents($argv[2]), Yaml::PARSE_OBJECT_FOR_MAP);
} catch (Exception $e) {
    echo "  ❌  Unable to parse schema file.\n";
    echo "      {$e->getMessage()}\n";
    die();
}
try {
    $credentialsFile = Yaml::parse(file_get_contents($argv[1]), Yaml::PARSE_OBJECT_FOR_MAP);
} catch (Exception $e) {
    echo "  ❌  Unable to parse credentials file.\n";
    echo "      {$e->getMessage()}\n";
    die();
}

$rx = new Rx\Rx();

// Add custom types
if ($argv[3]) {
    $types = explode(';', $argv[3]);
    foreach($types as $type) {
        try {
            $typeFile = Yaml::parse(file_get_contents($type), Yaml::PARSE_OBJECT_FOR_MAP);
            $rx->learnType($typeFile->uri, $typeFile->schema);
        } catch (Exception $e) {
            echo "  ❌  Unable to add custom types.\n";
            echo "      {$e->getMessage()}\n";
            die();        
        }
    }
}

try {
    $schema = $rx->makeSchema($schemaFile);
    echo "  ✅  Schema loaded successfully.\n";
} catch (Exception $e) {
    echo "  ❌  An error occurred loading the schema.\n";
    echo "      {$e->getMessage()}\n";
    die();
}

try {
    $schema->check($credentialsFile);
    echo "  ✅  File is according to schema.\n";
} catch (Exception $e) {
    echo "  ❌  An error occurred validating the file against the schema.\n";
    echo "      {$e->getMessage()}\n";
}
