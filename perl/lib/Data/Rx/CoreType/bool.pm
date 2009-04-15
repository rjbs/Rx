use strict;
use warnings;
package Data::Rx::CoreType::bool;
use base 'Data::Rx::CoreType';
# ABSTRACT: the Rx //bool type

sub validate {
  my ($self, $value) = @_;

  die unless(
    defined($value)
    and ref($value)
    and (
      eval { $value->isa('JSON::XS::Boolean') }
      or
      eval { $value->isa('JSON::PP::Boolean') }
      or
      eval { $value->isa('boolean') }
    )
  );

  return 1;
}

sub subname   { 'bool' }

1;
