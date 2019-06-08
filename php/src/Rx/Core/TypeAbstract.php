<?php
declare(strict_types=1);

namespace Rx\Core;

use Rx\Rx;

abstract class TypeAbstract
{

    use CheckSchemaTrait;

    protected $propName;

    public function __construct(\stdClass $schema, Rx $rx, ?string $propName = null)
    {

        $this->propName = $propName;

        $this->checkSchema($schema);

    }

}