use strict;
use warnings;
package Data::Rx::CoreType::txt;
use base 'Data::Rx::CoreType';

sub check {
  my ($self, $value) = @_;

  return unless defined $value and ! ref $value;
  return 1;
}

sub authority { '' }
sub type      { 'txt' }

1;
