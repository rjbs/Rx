<?php

namespace Rx\Core;

use Rx\Exception\RxException;
use Rx\Util;

trait CheckSchemaTrait
{

    private function checkSchema(\stdClass $schema): void
    {

        foreach ($schema as $key => $entry) {
            if (!in_array($key, static::VALID_PARAMS)) {
                throw new RxException(sprintf('Unknown key `%s` in %s %s.', $key, Util::formatPropName($this->propName), static::TYPE));
            }
        }

    }

}