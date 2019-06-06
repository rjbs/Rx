<?php
declare(strict_types=1);

namespace Rx\Core\Type;

use Rx\Core\{TypeInterface, CheckSchemaTrait};
use Rx\{Rx, RangeChecker, Util};
use Rx\Exception\MissingParamException;

class Arr implements TypeInterface
{

    use CheckSchemaTrait;

    const URI = 'tag:codesimply.com,2008:rx/core/arr';
    const TYPE = '//arr';
    const VALID_PARAMS = [
        'contents',
        'length',
        'type',
    ];

    private $contentSchema;
    private $lengthChecker;

    public function __construct(\stdClass $schema, Rx $rx)
    {

        $this->checkSchema($schema, static::TYPE);

        if (empty($schema->contents)) {
            throw new MissingParamException('No `contents` param for //arr schema');
        }

        $this->contentSchema = $rx->makeSchema($schema->contents);

        if (isset($schema->length)) {
            $this->lengthChecker = new RangeChecker($schema->length);
        }

    }

    public function check($value): bool
    {

        if (! Util::isSeqIntArray($value)) {
            return false;
        }

        if ($this->lengthChecker) {
            if (! $this->lengthChecker->check(count($value))) {
                return false;
            }
        }

        foreach ($value as $i => $entry) {
            if (! $this->contentSchema->check($entry)) {
                return false;
            }
        }

        return true;

    }

}