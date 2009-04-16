use strict;
use warnings;
package Data::Rx::CoreType::int;
use base 'Data::Rx::CoreType::num';
# ABSTRACT: the Rx //int type

sub subname   { 'int' }

sub validate {
  my ($self, $value) = @_;
  $self->SUPER::validate($value);

  return 1 if $value == int $value;

  $self->fail({
    error   => [ qw(type) ],
    message => "found value is not an integer",
  });
}

1;
