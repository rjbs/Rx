<?php
declare(strict_types=1);

namespace Rx;

final class RangeChecker
{

    const VALID_ARGS = ['min', 'max', 'min-ex', 'max-ex'];
    const ARGS_PROPS = ['min' => 'min', 'max' => 'max', 'min-ex' => 'minEx', 'max-ex' => 'maxEx'];

    protected $min;
    protected $minEx;
    protected $maxEx;
    protected $max;

    public function __construct(\stdClass $arg)
    {

        foreach (self::VALID_ARGS as $name) {
            if (! property_exists($arg, $name)) {
                continue;
            }
            $this->{self::ARGS_PROPS[$name]} = $arg->$name;
        }

    }

    public function check($value): bool
    {

        if (! is_null($this->min)   && $value <  $this->min  ) { return false; }
        if (! is_null($this->minEx) && $value <= $this->minEx) { return false; }
        if (! is_null($this->maxEx) && $value >= $this->maxEx) { return false; }
        if (! is_null($this->max)   && $value >  $this->max  ) { return false; }

        return true;

    }

}