use strict;
use warnings;
package Data::Rx::CoreType::nil;
use base 'Data::Rx::CoreType';
# ABSTRACT: the Rx //nil type
use Data::Rx::Failure;

sub check {
  my ($self, $value) = @_;

  return (! defined $value or Data::Rx::Failure->new($self,{
      message => "<$value> is not an undef",
      value=>$value,
  }));
}

sub subname   { 'nil' }

1;
