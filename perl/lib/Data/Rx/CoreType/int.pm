use strict;
use warnings;
package Data::Rx::CoreType::int;
use base 'Data::Rx::CoreType::num';
# ABSTRACT: the Rx //int type

sub subname   { 'int' }

sub validate {
  my ($self, $value) = @_;
  $self->SUPER::validate($value);
  die unless $value == int $value;
  return 1;
}

1;
