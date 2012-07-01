use strict;
use warnings;
package Data::Rx::CoreType::fail;
use parent 'Data::Rx::CoreType';
# ABSTRACT: the Rx //fail type

sub assert_valid {
  $_[0]->fail({
    error   => [ qw(fail) ],
    message => "matching reached an always-fail check",
    value   => $_[1],
  });
}

sub subname   { 'fail' }

1;
