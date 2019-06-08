<?php
declare(strict_types=1);

namespace Rx;

final class Util
{

    public static function isSeqIntArray($value): bool
    {

        if (! is_array($value)) {
            return false;
        }

        for ($i = 0; $i < count($value); $i++) {
            if (! array_key_exists($i, $value)) {
                return false;
            }
        }

        return true;

    }

    public static function formatPropName(?string $propName = null): string
    {

        return $propName ? sprintf('`%s`', $propName) : '_TOP_';

    }

}