use strict;
use warnings;
package Data::Rx::CoreType::def;
use base 'Data::Rx::CoreType';
# ABSTRACT: the Rx //def type
use Data::Rx::Failure;

sub check {
  my ($self, $value) = @_;

  return (defined $value or Data::Rx::Failure->new($self,{
      message => 'not a defined value',
      value=>$value,
  }));
}

sub subname   { 'def' }

1;
