<?php
declare(strict_types=1);

namespace Rx\Core\Type;

use Rx\Core\{
    TypeAbstract,
    TypeInterface
};
use Rx\{
    Rx, 
    RangeChecker,
    Util
};
use Rx\Exception\{
    InvalidParamTypeException, 
    CheckFailedException
};

class Str extends TypeAbstract implements TypeInterface
{

    const URI = 'tag:codesimply.com,2008:rx/core/str';
    const TYPE = '//str';
    const VALID_PARAMS = [
        'value',
        'type',
        'length',
    ];

    private $fixedValue;
    private $lengthChecker;

    public function __construct(\stdClass $schema, Rx $rx, ?string $propName = null)
    {

        parent::__construct($schema, $rx, $propName);

        if (isset($schema->value)) {
            if (! is_string($schema->value)) {
                throw new InvalidParamTypeException(sprintf('The `value` for %s %s is not a string.', Util::formatPropName($this->propName), static::TYPE));
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
            throw new CheckFailedException(sprintf('Key `%s` is not of type %s.', $this->propName, static::TYPE));
        }
        if ($this->fixedValue !== null && $value != $this->fixedValue) {
            throw new CheckFailedException(sprintf('\'%s\' does not equal value \'%s\' in `%s` %s.', strval($value), strval($this->fixedValue), $this->propName, static::TYPE));
        }
    
        if ($this->lengthChecker && ! $this->lengthChecker->check(strlen($value))) {
            throw new CheckFailedException(sprintf('\'%s\' length check fails in `%s` %s.', strval($value), $this->propName, static::TYPE));
        }

        return true;

    }

}