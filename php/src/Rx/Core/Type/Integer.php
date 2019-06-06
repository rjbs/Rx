<?php
declare(strict_types=1);

namespace Rx\Core\Type;

use Rx\Core\{TypeInterface};

/**
 * Can't use Int as class name
 */
class Integer extends Num implements TypeInterface
{

    const URI = 'tag:codesimply.com,2008:rx/core/int';
    const TYPE = '//int';

}