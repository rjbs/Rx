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
    RequiredAndOptionalException, 
    CheckFailedException
};

class Rec extends TypeAbstract implements TypeInterface
{

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
  
    public function __construct(\stdClass $schema, Rx $rx, ?string $propName = null)
    {

        parent::__construct($schema, $rx, $propName);

        $this->required = new \stdClass();
        $this->optional = new \stdClass();
        $this->known  = new \stdClass();
    
        if (isset($schema->rest)) {
            $this->restSchema = $rx->makeSchema($schema->rest, $propName);
        }
    
        if (isset($schema->required)) {
            foreach ($schema->required as $key => $entry) {
                $this->known->$key = true;
                $this->required->$key = $rx->makeSchema($entry, ($propName ? $propName . '->' : '') . $key);
            }
        }
    
        if (isset($schema->optional)) {
            foreach ($schema->optional as $key => $entry) {
                if (isset($this->known->$key)) {
                    throw new RequiredAndOptionalException(sprintf('`%s` is both required and optional in %s %s', $key, Util::formatPropName($this->propName), static::TYPE));
                }
                $this->known->$key = true;
                $this->optional->$key = $rx->makeSchema($entry, ($propName ? $propName . '->' : '') . $key);
            }
        }

    }

    public function check($value): bool
    {

        if (!is_object($value) || get_class($value) != 'stdClass') {
            throw new CheckFailedException(sprintf('Expected object, got %s in %s %s.', gettype($value), Util::formatPropName($this->propName), static::TYPE));
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
            throw new CheckFailedException(sprintf('Invalid keys [%s] found in %s %s.', implode(', ', array_keys(get_object_vars($rest))), Util::formatPropName($this->propName), static::TYPE));
        }
    
        foreach ($this->required as $key => $schema) {
            if (! property_exists($value, $key)) {
                throw new CheckFailedException(sprintf('Value for `%s` not found in `required` of %s %s.', strval($key), Util::formatPropName($this->propName), static::TYPE));
            }
            $schema->check($value->$key);
        }
    
        foreach ($this->optional as $key => $schema) {
            if (! property_exists($value, $key)) {
                continue;
            }
            $schema->check($value->$key);
        }
    
        if ($haveRest) {
            $this->restSchema->check($rest);
        }
    
        return true;

    }

}