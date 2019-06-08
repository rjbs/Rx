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

class Boolean extends TypeAbstract implements TypeInterface
{

    const URI = 'tag:codesimply.com,2008:rx/core/bool';
    const TYPE = '//bool';
    const VALID_PARAMS = [
        'type',
    ];

    function check($value): bool
    {

        if (! is_bool($value)) {
            throw new CheckFailedException(sprintf('Key %s is not of type %s.', Util::formatPropName($this->propName), static::TYPE));
        }

        return true;

    }

}