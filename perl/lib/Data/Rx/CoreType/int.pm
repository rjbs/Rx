use strict;
use warnings;
package Data::Rx::CoreType::int;
use base 'Data::Rx::CoreType::num';
# ABSTRACT: the Rx //int type

sub subname   { 'int' }

sub __type_fail {
  my ($self, $value) = @_;
  $self->fail({
    error   => [ qw(type) ],
    message => "value is not an integer",
    value   => $value,
  });
}

sub _value_is_of_type {
  my ($self, $value) = @_;

  return unless $self->SUPER::_value_is_of_type($value);
  return ($value == int $value);
}

1;
