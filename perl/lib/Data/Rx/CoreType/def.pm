use strict;
use warnings;
package Data::Rx::CoreType::def;
use base 'Data::Rx::CoreType';
# ABSTRACT: the Rx //def type

sub check {
  my ($self, $value) = @_;

  return defined $value;
}

sub subname   { 'def' }

1;
