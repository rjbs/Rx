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

class One extends TypeAbstract implements TypeInterface
{

    const URI = 'tag:codesimply.com,2008:rx/core/one';
    const TYPE = '//one';
    const VALID_PARAMS = [
        'type',
    ];

    public function check($value): bool
    {

        if (! is_scalar($value)) {
            throw new CheckFailedException(sprintf('Key %s is not of type %s.', Util::formatPropName($this->propName), static::TYPE));
        }

        return true;

    }

}