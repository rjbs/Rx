use strict;
use warnings;
package Data::Rx::CoreType::fail;
use base 'Data::Rx::CoreType';
# ABSTRACT: the Rx //fail type

sub validate {
  $_[0]->fail({
    error   => [ qw(alwaysfail) ],
    message => "matching reached an always-fail check",
  });
}

sub subname   { 'fail' }

1;
