use strict;
use warnings;
package Data::Rx::CoreType::nil;
use base 'Data::Rx::CoreType';
# ABSTRACT: the Rx //nil type

sub validate {
  my ($self, $value) = @_;

  die if defined $value;
  return 1;
}

sub subname   { 'nil' }

1;
