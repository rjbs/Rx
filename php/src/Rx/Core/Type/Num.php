<?php
declare(strict_types=1);

namespace Rx\Core\Type;

use Rx\Core\{
    TypeAbstract,
    TypeInterface
};
use Rx\{
    Rx, 
    RangeChecker
};
use Rx\Exception\{
    InvalidParamTypeException, 
    CheckFailedException
};

class Num extends TypeAbstract implements TypeInterface
{

    const URI = 'tag:codesimply.com,2008:rx/core/num';
    const TYPE = '//num';
    const VALID_PARAMS = [
        'range',
        'type',
        'value',
    ];

    private $rangeChecker;
    private $fixedValue;

    public function __construct(\stdClass $schema, Rx $rx, ?string $propName = null)
    {

        parent::__construct($schema, $rx, $propName);

        if (isset($schema->value)) {
            if (! (is_int($schema->value) || is_float($schema->value))) {
                throw new InvalidParamTypeException(sprintf('The `value` param for %s schema is not an int or float.', static::TYPE));
            }
            if (static::TYPE == '//int' && is_float($schema->value) && $schema->value != floor($schema->value)) {
                throw new InvalidParamTypeException(sprintf('The `value` param for %s schema is not an int', static::TYPE));
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
            throw new CheckFailedException(sprintf('Expected int/float, got %s in %s.', gettype($value), static::TYPE));
        }
        if (static::TYPE == '//int' && is_float($value) && $value != floor($value)) {
            throw new CheckFailedException(sprintf('Key `%s` is not of type %s.', $this->propName, static::TYPE));
        }

        if ($this->fixedValue !== null) {
            if ($value != $this->fixedValue) {
                throw new CheckFailedException(sprintf('Value does not equal value \'%s\' in %s.', strval($this->fixedValue), static::TYPE));
            }
        }

        if ($this->rangeChecker && ! $this->rangeChecker->check($value)) {
            throw new CheckFailedException(sprintf('Range check fails in %s.', static::TYPE));
        }

        return true;

    }

}