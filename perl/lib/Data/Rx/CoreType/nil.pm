use strict;
use warnings;
package Data::Rx::CoreType::nil;
use base 'Data::Rx::CoreType';
# ABSTRACT: Rx '//nil' type

sub check {
  my ($self, $value) = @_;

  return ! defined $value;
}

sub subname   { 'nil' }

1;
