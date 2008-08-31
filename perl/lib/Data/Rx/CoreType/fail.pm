use strict;
use warnings;
package Data::Rx::CoreType::fail;
use base 'Data::Rx::CoreType';
# ABSTRACT: Rx '//fail' type

sub check { return}

sub subname   { 'fail' }

1;
