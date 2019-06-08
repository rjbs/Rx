<?php
declare(strict_types=1);

namespace Rx\Core\Type;

use Rx\Core\{
    TypeAbstract,
    TypeInterface
};
use Rx\{
    Rx,
    Util
};
use Rx\Exception\{
    NoAlternativesGivenException, 
    CheckFailedException
};

class Any extends TypeAbstract implements TypeInterface
{

    const URI = 'tag:codesimply.com,2008:rx/core/any';
    const TYPE = '//any';
    const VALID_PARAMS = [
        'of',
        'type',
    ];

    private $alts = [];

    public function __construct(\stdClass $schema, Rx $rx, ?string $propName = null)
    {

        parent::__construct($schema, $rx, $propName);

        if (property_exists($schema, 'of')) {
            if (empty($schema->of)) {
                throw new NoAlternativesGivenException(sprintf("No `of` given in %s %s.", Util::formatPropName($this->propName), static::TYPE));
            }
            foreach ($schema->of as $alt) {
                $this->alts[] = $rx->makeSchema($alt, $propName);
            }
        }
    }

    public function check($value): bool
    {

        if (empty($this->alts)) {
            return true;
        }

        foreach ($this->alts as $alt) {
            try {
                if ($alt->check($value)) {
                    return true;
                }
            } catch (CheckFailedException $e) {
                // ignore
            }
        }

        throw new CheckFailedException(sprintf('Values in %s %s do not match any `of`.', Util::formatPropName($this->propName), static::TYPE));

    }

}