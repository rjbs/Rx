<?php

namespace Rx\Core;

interface TypeInterface
{
    public function check($value): bool;
}