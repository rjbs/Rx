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
    MissingParamException, 
    InvalidParamTypeException, 
    CheckFailedException
};

class Seq extends TypeAbstract implements TypeInterface
{

    const URI = 'tag:codesimply.com,2008:rx/core/seq';
    const TYPE = '//seq';
    const VALID_PARAMS = [
        'contents',
        'tail',
        'type',
    ];

    private $contentSchemata;
    private $tailSchema;
  
    public function __construct(\stdClass $schema, Rx $rx, ?string $propName = null)
    {

        parent::__construct($schema, $rx, $propName);

        if (! isset($schema->contents)) {
            throw new MissingParamException(sprintf('No `contents` param for %s %s schema', $propName, static::TYPE));
        }
    
        if (! is_array($schema->contents)) {
            throw new InvalidParamTypeException(sprintf('The `contents` param for %s %s schema is not an array', $propName, static::TYPE));
        }
  
        $this->contentSchemata = [];
  
        foreach ($schema->contents as $i => $entry) {
            $this->contentSchemata[] = $rx->makeSchema($entry, 'seq#' . $i);
        }
  
        if (isset($schema->tail)) {
            $this->tailSchema = $rx->makeSchema($schema->tail);
        }
  
    }

    public function check($value): bool
    {

        if (! Util::isSeqIntArray($value)) {
            throw new CheckFailedException(sprintf('Numeric keys not found in %s %s.', $this->propName, static::TYPE));
        }
  
        foreach ($this->contentSchemata as $i => $schema) {
            if (! array_key_exists($i, $value)) {
                throw new CheckFailedException(sprintf('Key `%s` not found in `contents` of %s %s', strval($i), $this->propName, static::TYPE));
            }
            $schema->check($value[$i]);
        }
    
        if (count($value) > count($this->contentSchemata)) {
            if (! $this->tailSchema) {
                throw new CheckFailedException(sprintf('`tail` missing from, or invalid length of %s', static::TYPE));
            }
    
            $tail = array_slice(
                    $value,
                    count($this->contentSchemata),
                    count($value) - count($this->contentSchemata)
            );
    
            $this->tailSchema->check($tail);
        }
    
        return true;

    }

}