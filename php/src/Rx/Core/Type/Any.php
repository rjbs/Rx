<?php
declare(strict_types=1);

namespace Rx\Core\Type;

use Rx\Core\{TypeInterface, CheckSchemaTrait};
use Rx\Rx;
use Rx\Exception\NoAlternativesGivenException;

class Any implements TypeInterface
{

    use CheckSchemaTrait;

    const URI = 'tag:codesimply.com,2008:rx/core/any';
    const TYPE = '//any';
    const VALID_PARAMS = [
        'of',
        'type',
    ];

    private $alts = [];

    public function __construct(\stdClass $schema, Rx $rx)
    {

        $this->checkSchema($schema, static::TYPE);

        if (property_exists($schema, 'of')) {
            if (empty($schema->of)) {
                throw new NoAlternativesGivenException("No alternatives given for //any `of`");
            }
            foreach ($schema->of as $alt) {
                $this->alts[] = $rx->makeSchema($alt);
            }
        }
    }

    public function check($value): bool
    {

        if (empty($this->alts)) {
            return true;
        }
        foreach ($this->alts as $alt) {
            if ($alt->check($value)) {
                return true;
            }
        }

        return false;

    }

}