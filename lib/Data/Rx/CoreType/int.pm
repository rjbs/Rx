use strict;
use warnings;
package Data::Rx::CoreType::int;
use base 'Data::Rx::CoreType::num';

sub authority { '' }
sub type      { 'int' }

sub check {
  my ($self, $value) = @_;
  return unless $self->SUPER::check($value);
  return unless $value == int $value;
  return 1;
}

1;
