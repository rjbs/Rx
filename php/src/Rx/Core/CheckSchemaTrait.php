<?php

namespace Rx\Core;

trait CheckSchemaTrait
{

    private function checkSchema(\stdClass $schema, string $type): void
    {

        foreach ($schema as $key => $entry) {
            if (!in_array($key, static::VALID_PARAMS)) {
                throw new \Exception("Unknown parameter $key for $type schema");
            }
        }

    }

}