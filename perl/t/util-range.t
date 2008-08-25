use strict;
use warnings;

use Test::More 'no_plan';

use Data::Rx::Util;

{
  my $sub = Data::Rx::Util->_make_range_check( { min => 1, max => 10 } );

  ok(! $sub->(0),  "! 1 <= 1 <= 10");
  ok($sub->(1),    "1 <= 1 <= 10");
  ok($sub->(5),    "1 <= 5 <= 10");
  ok($sub->(8),    "1 <= 8 < 7 <= 10");
  ok(! $sub->(15), "! 1 <= 15 <= 10");
}

{
  my $sub = Data::Rx::Util->_make_range_check(
    { min => 1, max => 10, 'max-ex' => 7 },
  );

  ok(! $sub->(0),  "! 1 <= 1 < 7 <= 10");
  ok($sub->(1),    "1 <= 1 < 7 <= 10");
  ok($sub->(5),    "1 <= 5 < 7 <= 10");
  ok(! $sub->(8),  "! 1 <= 8 < 7 <= 10");
  ok(! $sub->(15), "! 1 <= 15 < 7 <= 10");
}
