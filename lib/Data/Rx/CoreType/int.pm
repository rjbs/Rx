use strict;
use warnings;
package Data::Rx::CoreType::int;
use base 'Data::Rx::CoreType::num';

sub _dec_re { '' }

sub authority { '' }
sub type      { 'int' }

1;
