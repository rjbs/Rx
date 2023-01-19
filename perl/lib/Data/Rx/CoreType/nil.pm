use v5.12.0;
use warnings;
package Data::Rx::CoreType::nil;
# ABSTRACT: the Rx //nil type

use parent 'Data::Rx::CoreType';

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
