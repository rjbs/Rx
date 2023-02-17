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

class Nil extends TypeAbstract implements TypeInterface
{

    const URI = 'tag:codesimply.com,2008:rx/core/nil';
    const TYPE = '//nil';
    const VALID_PARAMS = [
        'type',
    ];

    public function check($value): bool
    {

        if (! is_null($value)) {
            throw new CheckFailedException(sprintf('Key %s is not of type %s.', Util::formatPropName($this->propName), static::TYPE));
        }

        return true;

    }

}