use strict;
use warnings;
package Data::Rx::CoreType::bool;
use base 'Data::Rx::CoreType';
# ABSTRACT: Rx '//bool' type

sub check {
  my ($self, $value) = @_;

  return(
    defined($value)
    and ref($value)
    and (
      eval { $value->isa('JSON::XS::Boolean') }
      or
      eval { $value->isa('boolean') }
    )
  );
}

sub subname   { 'bool' }

1;
