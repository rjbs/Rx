<?php
declare(strict_types=1);

namespace Rx\Core\Type;

use Rx\Core\{TypeInterface, CheckSchemaTrait};
use Rx\Rx;

class Map implements TypeInterface
{

    use CheckSchemaTrait;

    const URI = 'tag:codesimply.com,2008:rx/core/map';
    const TYPE = '//map';
    const VALID_PARAMS = [
        'values',
        'type',
    ];

    private $valuesSchema;

    public function __construct(\stdClass $schema, Rx $rx)
    {

        $this->checkSchema($schema, static::TYPE);

        if ($schema->values) {
            $this->valuesSchema = $rx->makeSchema($schema->values);
        }

    }

    public function check($value): bool
    {

        if (!is_object($value) || get_class($value) != 'stdClass') {
            return false;
        }

        if ($this->valuesSchema) {
            foreach ($value as $key => $entry) {
                if (! $this->valuesSchema->check($entry)) {
                    return false;
                }
            }
        }

        return true;

    }

}