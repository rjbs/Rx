use strict;
use warnings;
package Data::Rx::CoreType::fail;
use base 'Data::Rx::CoreType';
# ABSTRACT: the Rx //fail type
use Data::Rx::Failure;

sub check { return Data::Rx::Failure->new($_[0],{message=>'forced failure'}) }

sub subname   { 'fail' }

1;
