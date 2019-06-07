<?php

namespace Rx\Core;

use Rx\Rx;

interface TypeInterface
{
    public function __construct(\stdClass $schema, Rx $rx, ?string $propName = null);
    public function check($value): bool;
}