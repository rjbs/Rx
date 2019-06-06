<?php
declare(strict_types=1);

namespace Rx\Core\Type;

use Rx\Core\{TypeInterface, CheckSchemaTrait};
use Rx\{Rx, Util};
use Rx\Exception\{MissingParamException, InvalidParamTypeException};

class Seq implements TypeInterface
{

    use CheckSchemaTrait;

    const URI = 'tag:codesimply.com,2008:rx/core/seq';
    const TYPE = '//seq';
    const VALID_PARAMS = [
        'contents',
        'tail',
        'type',
    ];

    private $contentSchemata;
    private $tailSchema;
  
    public function __construct(\stdClass $schema, Rx $rx)
    {

        $this->checkSchema($schema, static::TYPE);

        if (! isset($schema->contents)) {
            throw new MissingParamException('No `contents` param for //seq schema');
        }
    
        if (! is_array($schema->contents)) {
            throw new InvalidParamTypeException('The `contents` param for //seq schema is not an array');
        }
  
        $this->contentSchemata = [];
  
        foreach ($schema->contents as $i => $entry) {
            $this->contentSchemata[] = $rx->makeSchema($entry);
        }
  
        if (isset($schema->tail)) {
            $this->tailSchema = $rx->makeSchema($schema->tail);
        }
  
    }

    public function check($value): bool
    {

        if (! Util::isSeqIntArray($value)) {
            return false;
        }
  
        foreach ($this->contentSchemata as $i => $schema) {
            if (! array_key_exists($i, $value)) {
                return false;
            }
            if (! $schema->check($value[$i])) {
                return false;
            }
        }
    
        if (count($value) > count($this->contentSchemata)) {
            if (! $this->tailSchema) {
                return false;
            }
    
            $tail = array_slice(
                    $value,
                    count($this->contentSchemata),
                    count($value) - count($this->contentSchemata)
            );
    
            if (! $this->tailSchema->check($tail)) {
                return false;
            }
        }
    
        return true;

    }

}