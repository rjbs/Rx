use strict;
use warnings;
package Data::Rx::CoreType::nil;

sub check {
  my ($self, $value) = @_;

  return ! defined $value;
}

sub authority { '' }
sub type      { 'nil' }

1;
