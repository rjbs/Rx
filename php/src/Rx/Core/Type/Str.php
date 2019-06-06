<?php
declare(strict_types=1);

namespace Rx\Core\Type;

use Rx\Core\{TypeInterface, CheckSchemaTrait};
use Rx\{Rx, RangeChecker};
use Rx\Exception\InvalidParamTypeException;

class Str implements TypeInterface
{

    use CheckSchemaTrait;

    const URI = 'tag:codesimply.com,2008:rx/core/str';
    const TYPE = '//str';
    const VALID_PARAMS = [
        'value',
        'type',
        'length',
    ];

    private $fixedValue;
    private $lengthChecker;  

    public function __construct(\stdClass $schema, Rx $rx)
    {

        $this->checkSchema($schema, static::TYPE);

        if (isset($schema->value)) {
            if (! is_string($schema->value)) {
                throw new InvalidParamTypeException('The `value` param for //str schema is not a string');
            }

            $this->fixedValue = $schema->value;
        }
      
        if (isset($schema->length)) {
            $this->lengthChecker = new RangeChecker($schema->length);
        }

    }

    public function check($value): bool
    {

        if (! is_string($value)) {
            return false;
        }
        if ($this->fixedValue !== null && $value != $this->fixedValue) {
            return false;
        }
    
        if ($this->lengthChecker) {
            if (! $this->lengthChecker->check(strlen($value))) {
                return false;
            }
        }

        return true;

    }

}