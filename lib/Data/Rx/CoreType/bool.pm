use strict;
use warnings;
package Data::Rx::CoreType::bool;

sub check {
  my ($self, $value) = @_;

  return(
    defined($value)
    and ref($value)
    and eval { $value->isa('JSON::XS::Boolean') }
  );
}

sub authority { '' }
sub type      { 'bool' }

1;
