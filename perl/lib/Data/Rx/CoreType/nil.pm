use strict;
use warnings;
package Data::Rx::CoreType::nil;
use base 'Data::Rx::CoreType';
# ABSTRACT: the Rx //nil type

sub assert_valid {
  my ($self, $value) = @_;

  return 1 if ! defined $value;

  $self->fail({
    error   => [ qw(type) ],
    message => "found value is defined",
    value   => $value,
  });
}

sub subname   { 'nil' }

1;
