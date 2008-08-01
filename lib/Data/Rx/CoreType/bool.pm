use strict;
use warnings;
package Data::Rx::CoreType::bool;
use base 'Data::Rx::CoreType';

sub check {
  my ($self, $value) = @_;

  return(
    defined($value)
    and ref($value)
    and eval { $value->isa('JSON::XS::Boolean') }
  );
}

sub authority { '' }
sub subname   { 'bool' }

1;
