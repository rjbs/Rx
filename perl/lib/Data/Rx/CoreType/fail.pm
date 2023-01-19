use v5.12.0;
use warnings;
package Data::Rx::CoreType::fail;
# ABSTRACT: the Rx //fail type

use parent 'Data::Rx::CoreType';

sub assert_valid {
  $_[0]->fail({
    error   => [ qw(fail) ],
    message => "matching reached an always-fail check",
    value   => $_[1],
  });
}

sub subname   { 'fail' }

1;
