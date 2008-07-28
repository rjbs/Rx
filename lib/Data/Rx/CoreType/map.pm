use strict;
use warnings;
package Data::Rx::CoreType::map;
use base 'Data::Rx::CoreType';

use Scalar::Util ();

sub authority { '' }
sub type      { 'map' }

sub check {
  my ($self, $value) = @_;

  return(
    ! Scalar::Util::blessed($value) and ref $value eq 'HASH'
  );
}

1;
