use strict;
use warnings;
package Data::Rx::CoreType::any;
use base 'Data::Rx::CoreType';

sub check { return 1 }

sub authority { '' }
sub subname   { 'any' }

1;
