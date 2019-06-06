<?php
declare(strict_types=1);

namespace Rx\Core\Type;

use Rx\Core\{TypeInterface, CheckSchemaTrait};
use Rx\Rx;

/**
 * Can't use Bool as class name
 */
class Boolean implements TypeInterface
{

    use CheckSchemaTrait;

    const URI = 'tag:codesimply.com,2008:rx/core/bool';
    const TYPE = '//bool';
    const VALID_PARAMS = [
        'type',
    ];

    public function __construct(\stdClass $schema, Rx $rx)
    {

        $this->checkSchema($schema, static::TYPE);

    }

    function check($value): bool
    {

        return is_bool($value);

    }

}