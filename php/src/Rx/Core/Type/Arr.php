<?php
declare(strict_types=1);

namespace Rx\Core\Type;

use Rx\Core\{
    TypeAbstract,
    TypeInterface, 
};
use Rx\{
    Rx, 
    RangeChecker, 
    Util
};
use Rx\Exception\{
    MissingParamException, 
    CheckFailedException
};

class Arr extends TypeAbstract implements TypeInterface
{

    const URI = 'tag:codesimply.com,2008:rx/core/arr';
    const TYPE = '//arr';
    const VALID_PARAMS = [
        'contents',
        'length',
        'type',
    ];

    private $contentSchema;
    private $lengthChecker;

    public function __construct(\stdClass $schema, Rx $rx, ?string $propName = null)
    {

        parent::__construct($schema, $rx, $propName);

        if (empty($schema->contents)) {
            throw new MissingParamException(sprintf('No `contents` key found for %s %s.', Util::formatPropName($this->propName), static::TYPE));
        }

        $this->contentSchema = $rx->makeSchema($schema->contents, $propName);

        if (isset($schema->length)) {
            $this->lengthChecker = new RangeChecker($schema->length);
        }

    }

    public function check($value): bool
    {

        if (! Util::isSeqIntArray($value)) {
            throw new CheckFailedException(sprintf('Numeric keys not found in %s %s.', Util::formatPropName($this->propName), static::TYPE));
        }

        if ($this->lengthChecker) {
            if (! $this->lengthChecker->check(count($value))) {
                throw new CheckFailedException(sprintf('Array length check fails in %s %s.', Util::formatPropName($this->propName), static::TYPE));
            }
        }

        foreach ($value as $i => $entry) {
            $this->contentSchema->check($entry);
        }

        return true;

    }

}