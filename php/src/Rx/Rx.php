<?php
declare(strict_types=1);

namespace Rx;

use Rx\Exception\RxException;

final class Rx
{

    const CORE_TYPES = [
        'All', 'Any', 'Arr', 'Boolean', 'Def', 'Fail', 'Integer', 'Map', 'Nil', 'Num', 'One', 'Rec', 'Seq', 'Str',
    ];

    protected $typeRegistry;
    protected $prefixRegistry = [
        ''      => 'tag:codesimply.com,2008:rx/core/',
        '.meta' => 'tag:codesimply.com,2008:rx/meta/',
    ];

    function __construct()
    {

        $this->typeRegistry = new \stdClass();

        foreach (self::CORE_TYPES as $className) {
            $fullClassName = 'Rx\\Core\\Type\\' . $className;
            $this->typeRegistry->{$fullClassName::URI} = $fullClassName;
        }

    }

    private function expandUri(string $name): string
    {

        if (preg_match('/^\w+:/', $name)) {
            return $name;
        }

        if (preg_match('/^\\/(.*?)\\/(.+)$/', $name, $matches)) {
            if (! array_key_exists($matches[1], $this->prefixRegistry)) {
                throw new RxException("Unknown type prefix '$matches[1]' in '$name'.");
            }
            $uri = $this->prefixRegistry[ $matches[1] ] . $matches[2];
            return $uri;
        }

        throw new RxException("Couldn't understand type name '$name'.");

    }

    public function addPrefix(string $name, string $base): void
    {

        if (isset($this->prefixRegistry[$name])) {
            throw new RxException("The prefix '$name' is already registered.");
        }

        $this->prefixRegistry[$name] = $base;

    }

    public function learnType(string $uri, \stdClass $schema): void
    {

        if (isset($this->typeRegistry->$uri)) {
            throw new RxException("Failed to learn type for already-registered uri $uri.");
        }

        // Make sure schema is valid
        $this->makeSchema($schema);

        $this->typeRegistry->$uri = ['schema' => $schema];

    }

    public function makeSchema($schema, ?string $propName = null)
    {

        if (! is_object($schema)) {
            $schemaName = $schema;
            $schema = new \stdClass();
            $schema->type = $schemaName;
        }

        if (empty($schema->type)) {
            throw new RxException(sprintf('Can\'t make a schema without a `type` key in %s.', Util::formatPropName($propName)));
        }

        $uri = $this->expandUri($schema->type);

        if (! isset($this->typeRegistry->$uri)) {
            throw new RxException(sprintf('Unknown type \'%s\' in %s.', $uri, Util::formatPropName($propName)));
        }

        $typeClass = $this->typeRegistry->$uri;
  
        if (is_array($typeClass) && isset($typeClass['schema'])) {
            foreach ($schema as $key => $entry) {
                if ($key != 'type') {
                    throw new RxException(sprintf('Composed type does not take additional arguments in %s.', Util::formatPropName($propName)));
                }
            }
            return $this->makeSchema($typeClass['schema']);
        } elseif ($typeClass) {
            return new $typeClass($schema, $this, $propName);
        }

        return false;

    }

}