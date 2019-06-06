<?php
declare(strict_types=1);

namespace Rx\Core\Type;

use Rx\Core\{TypeInterface, CheckSchemaTrait};
use Rx\{Rx, RangeChecker};
use Rx\Exception\InvalidParamTypeException;

class Num implements TypeInterface
{

    use CheckSchemaTrait;

    const URI = 'tag:codesimply.com,2008:rx/core/num';
    const TYPE = '//num';
    const VALID_PARAMS = [
        'range',
        'type',
        'value',
    ];

    private $rangeChecker;
    private $fixedValue;

    public function __construct(\stdClass $schema, Rx $rx)
    {

        $this->checkSchema($schema, static::TYPE);

        if (isset($schema->value)) {
            if (! (is_int($schema->value) || is_float($schema->value))) {
                throw new InvalidParamTypeException('The `value` param for ' . static::TYPE . ' schema is not an int or float');
            }
            if (static::TYPE == '//int' && is_float($schema->value) && $schema->value != floor($schema->value)) {
                throw new InvalidParamTypeException('The `value` param for ' . static::TYPE . ' schema is not an int');
            }
            $this->fixedValue = $schema->value;
        }
    
        if (isset($schema->range)) {
            $this->rangeChecker = new RangeChecker($schema->range);
        }

    }

    public function check($value): bool
    {

        if (! (is_int($value) || is_float($value))) {
            return false;
        }
        if (static::TYPE == '//int' && is_float($value) && $value != floor($value)) {
            return false;
        }

        if ($this->fixedValue !== null) {
            if ($value != $this->fixedValue) {
                return false;
            }
        }

        if ($this->rangeChecker && ! $this->rangeChecker->check($value)) {
            return false;
        }

        return true;

    }

}