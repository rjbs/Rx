use strict;
use warnings;
package Data::Rx::CoreType::int;
use base 'Data::Rx::CoreType::num';
# ABSTRACT: the Rx //int type
use Data::Rx::Failure;

sub subname   { 'int' }

sub check {
  my ($self, $value) = @_;
  my $num = $self->SUPER::check($value);
  return $num unless $num;
  return Data::Rx::Failure->new($self,{
      message => "<$value> is not an integer",
      value=>$value,
  })
      unless $value == int $value;
  return 1;
}

1;
