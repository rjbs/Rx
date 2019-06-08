<?php
declare(strict_types=1);

namespace Rx\Core\Type;

use Rx\Core\{
    TypeAbstract,
    TypeInterface, 
};
use Rx\{
    Rx,
    Util
};
use Rx\Exception\CheckFailedException;

class Def extends TypeAbstract implements TypeInterface
{

    const URI = 'tag:codesimply.com,2008:rx/core/def';
    const TYPE = '//def';
    const VALID_PARAMS = [
        'type',
    ];

    public function check($value): bool
    {

        if (is_null($value)) {
            throw new CheckFailedException(sprintf('Value missing or not set in %s %s.', Util::formatPropName($this->propName), static::TYPE));
        }

        return true;

    }

}