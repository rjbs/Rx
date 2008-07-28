use strict;
use warnings;
package Data::Rx::CoreType::def;

sub check {
  my ($self, $value) = @_;

  return defined $value;
}

sub authority { '' }
sub type      { 'def' }

1;
