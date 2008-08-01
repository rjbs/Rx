use strict;
use warnings;
package Data::Rx::CoreType::scalar;
use base 'Data::Rx::CoreType';

sub check {
  my ($self, $value) = @_;

  return 1 if ! defined $value;
  return if ref $value and ! eval { $value->isa('JSON::XS::Boolean'); };
  return 1;
}

sub authority { '' }
sub type      { 'scalar' }

1;
