<?php
declare(strict_types=1);

namespace Rx\Core\Type;

use Rx\Core\{TypeInterface, CheckSchemaTrait};
use Rx\Rx;

class Nil implements TypeInterface
{

    use CheckSchemaTrait;

    const URI = 'tag:codesimply.com,2008:rx/core/nil';
    const TYPE = '//nil';
    const VALID_PARAMS = [
        'type',
    ];

    public function __construct(\stdClass $schema, Rx $rx)
    {

        $this->checkSchema($schema, static::TYPE);

    }

    public function check($value): bool
    {

        return is_null($value);

    }

}