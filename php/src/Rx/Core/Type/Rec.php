<?php
declare(strict_types=1);

namespace Rx\Core\Type;

use Rx\Core\{TypeInterface, CheckSchemaTrait};
use Rx\Rx;
use Rx\Exception\RequiredAndOptionalException;

class Rec implements TypeInterface
{

    use CheckSchemaTrait;

    const URI = 'tag:codesimply.com,2008:rx/core/rec';
    const TYPE = '//rec';
    const VALID_PARAMS = [
        'optional',
        'required',
        'rest',
        'type',
    ];

    private $required;
    private $optional;
    private $known;
    private $restSchema;
  
    public function __construct(\stdClass $schema, Rx $rx)
    {

        $this->checkSchema($schema, static::TYPE);

        $this->required = new \stdClass();
        $this->optional = new \stdClass();
        $this->known  = new \stdClass();
    
        if (isset($schema->rest)) {
            $this->restSchema = $rx->makeSchema($schema->rest);
        }
    
        if (isset($schema->required)) {
            foreach ($schema->required as $key => $entry) {
                $this->known->$key = true;
                $this->required->$key = $rx->makeSchema($entry);
            }
        }
    
        if (isset($schema->optional)) {
            foreach ($schema->optional as $key => $entry) {
                if (isset($this->known->$key)) {
                    throw new RequiredAndOptionalException("`$key` is both required and optional in //rec");
                }
        
                $this->known->$key = true;
                $this->optional->$key = $rx->makeSchema($entry);
            }
        }

    }

    public function check($value): bool
    {

        if (!is_object($value) || get_class($value) != 'stdClass') {
            return false;
        }

        $rest = new \stdClass();
        $haveRest = false;
    
        foreach ($value as $key => $entry) {
            if (! isset($this->known->$key)) {
                $haveRest = true;
                $rest->$key = $entry;
            }
        }
    
        if ($haveRest && ! $this->restSchema) {
            return false;
        }
    
        foreach ($this->required as $key => $schema) {
            if (! property_exists($value, $key)) {
                return false;
            }
            if (! $schema->check($value->$key)) {
                return false;
            }
        }
    
        foreach ($this->optional as $key => $schema) {
            if (! property_exists($value, $key)) {
                continue;
            }
            if (! $schema->check($value->$key)) {
                return false;
            }
        }
    
        if ($haveRest && ! $this->restSchema->check($rest)) {
            return false;
        }
    
        return true;

    }

}