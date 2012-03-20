use strict;
use warnings;
package Data::Rx::CoreType::one;
use base 'Data::Rx::CoreType';
# ABSTRACT: the Rx //one type
use Data::Rx::Failure;

sub check {
  my ($self, $value) = @_;

  return Data::Rx::Failure->new($self,{
      message => 'not a defined value',
      value=>$value,
  })
      if ! defined $value;
  return Data::Rx::Failure->new($self,{
      message => "<$value> is not a boolean",
      value=>$value,
  })
      if ref $value and ! (
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
