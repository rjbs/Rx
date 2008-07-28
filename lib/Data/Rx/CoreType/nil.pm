use strict;
use warnings;
package Data::Rx::CoreType::nil;
use base 'Data::Rx::CoreType';

sub check {
  my ($self, $value) = @_;

  return ! defined $value;
}

sub authority { '' }
sub type      { 'nil' }

1;
