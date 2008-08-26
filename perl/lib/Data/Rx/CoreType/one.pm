use strict;
use warnings;
package Data::Rx::CoreType::one;
use base 'Data::Rx::CoreType';

sub check {
  my ($self, $value) = @_;

  return if ! defined $value;
  return if ref $value and ! (
    eval { $value->isa('JSON::XS::Boolean') }
    or
    eval { $value->isa('boolean') }
  );
  return 1;
}

sub authority { '' }
sub subname   { 'one' }

1;
