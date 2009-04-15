use strict;
use warnings;
package Data::Rx::CoreType::one;
use base 'Data::Rx::CoreType';
# ABSTRACT: the Rx //one type

sub validate {
  my ($self, $value) = @_;

  die if ! defined $value;
  die if ref $value and ! (
    eval { $value->isa('JSON::XS::Boolean') }
    or
    eval { $value->isa('JSON::PP::Boolean') }
    or
    eval { $value->isa('boolean') }
  );
  return 1;
}

sub subname   { 'one' }

1;
