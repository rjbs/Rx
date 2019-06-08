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
            throw new MissingParamException(sprintf('No `contents` key for %s %s.', Util::formatPropName($this->propName), static::TYPE));
        }
    
        if (! is_array($schema->contents)) {
            throw new InvalidParamTypeException(sprintf('The `contents` for %s %s is not an array.', Util::formatPropName($this->propName), static::TYPE));
        }
  
        $this->contentSchemata = [];
  
        foreach ($schema->contents as $i => $entry) {
            $this->contentSchemata[] = $rx->makeSchema($entry, $propName . '->seq#' . $i);
        }
  
        if (isset($schema->tail)) {
            $this->tailSchema = $rx->makeSchema($schema->tail, $propName . '->tail');
        }
  
    }

    public function check($value): bool
    {

        if (! Util::isSeqIntArray($value)) {
            throw new CheckFailedException(sprintf('Numeric keys not found in %s %s.', Util::formatPropName($this->propName), static::TYPE));
        }
  
        foreach ($this->contentSchemata as $i => $schema) {
            if (! array_key_exists($i, $value)) {
                throw new CheckFailedException(sprintf('Value for `%s` not found in `contents` of %s %s.', strval($i), Util::formatPropName($this->propName), static::TYPE));
            }
            $schema->check($value[$i]);
        }
    
        if (count($value) > count($this->contentSchemata)) {
            if (! $this->tailSchema) {
                throw new CheckFailedException(sprintf('Key `tail` missing, or invalid length of %s %s.', Util::formatPropName($this->propName), static::TYPE));
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