<?php
declare(strict_types=1);

namespace Rx\Core\Type;

use Rx\Core\{
    TypeAbstract,
    TypeInterface
};
use Rx\{
    Rx,
    Util
};
use Rx\Exception\CheckFailedException;

class Map extends TypeAbstract implements TypeInterface
{

    const URI = 'tag:codesimply.com,2008:rx/core/map';
    const TYPE = '//map';
    const VALID_PARAMS = [
        'values',
        'type',
    ];

    private $valuesSchema;

    public function __construct(\stdClass $schema, Rx $rx, ?string $propName = null)
    {

        parent::__construct($schema, $rx, $propName);

        if (isset($schema->values)) {
            $this->valuesSchema = $rx->makeSchema($schema->values, $propName);
        }

    }

    public function check($value): bool
    {

        if (!is_object($value) || get_class($value) != 'stdClass') {
            throw new CheckFailedException(sprintf('Expected object, got %s in %s %s.', gettype($value), Util::formatPropName($this->propName), static::TYPE));
        }

        if ($this->valuesSchema) {
            foreach ($value as $key => $entry) {
                $this->valuesSchema->check($entry);
            }
        }

        return true;

    }

}