use strict;
use warnings;
package Data::Rx::CoreType::def;
use base 'Data::Rx::CoreType';
# ABSTRACT: the Rx //def type

sub validate {
  my ($self, $value) = @_;

  die unless defined $value;
  return 1;
}

sub subname   { 'def' }

1;
