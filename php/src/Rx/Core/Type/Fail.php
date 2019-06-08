<?php
declare(strict_types=1);

namespace Rx\Core\Type;

use Rx\Core\{
    TypeAbstract,
    TypeInterface
};
use Rx\Rx;
use Rx\Exception\CheckFailedException;

class Fail extends TypeAbstract implements TypeInterface
{

    const URI = 'tag:codesimply.com,2008:rx/core/fail';
    const TYPE = '//fail';
    const VALID_PARAMS = [
        'type',
    ];

    public function check($value): bool
    {

        throw new CheckFailedException('Failed as per //fail.');

    }

}