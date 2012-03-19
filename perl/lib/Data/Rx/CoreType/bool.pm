use strict;
use warnings;
package Data::Rx::CoreType::bool;
use base 'Data::Rx::CoreType';
# ABSTRACT: the Rx //bool type
use Data::Rx::Failure;

sub check {
  my ($self, $value) = @_;

  return Data::Rx::Failure->new($self,{
      message => 'not a defined value',
      value=>$value,
  })
      unless defined $value;

  return ((
    defined($value)
    and ref($value)
    and (
      eval { $value->isa('JSON::XS::Boolean') }
      or
      eval { $value->isa('JSON::PP::Boolean') }
      or
      eval { $value->isa('boolean') }
    )
  ) or Data::Rx::Failure->new($self,{
      message => "<$value> is not a boolean",
      value=>$value,
  }))
}

sub subname   { 'bool' }

1;
