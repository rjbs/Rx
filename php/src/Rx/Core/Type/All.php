<?php
declare(strict_types=1);

namespace Rx\Core\Type;

use Rx\Core\{
    TypeAbstract,
    TypeInterface, 
};
use Rx\{
    Rx,
    Util
};
use Rx\Exception\{
    NoAlternativesGivenException, 
    CheckFailedException
};

class All extends TypeAbstract implements TypeInterface
{

    const URI = 'tag:codesimply.com,2008:rx/core/all';
    const TYPE = '//all';
    const VALID_PARAMS = [
        'of',
        'type',
    ];

    private $alts = [];

    public function __construct(\stdClass $schema, Rx $rx, ?string $propName = null)
    {

        parent::__construct($schema, $rx, $propName);

        if (empty($schema->of)) {
            throw new NoAlternativesGivenException(sprintf("No `of` given in %s %s.", Util::formatPropName($this->propName), static::TYPE));
        }

        foreach ($schema->of as $alt) {
            $this->alts[] = $rx->makeSchema($alt, $propName);
        }

    }

    public function check($value): bool
    {

        foreach ($this->alts as $alt) {
            $alt->check($value);
        }

        return true;

    }

}