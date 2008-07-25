use strict;
use warnings;
use autodie;
use Test::More;

use lib 't/lib';
use Test::RxSpec;

plan tests => 14;
Test::RxSpec->test_spec('int');
