use strict;
use warnings;
package Data::Rx::CoreType;

sub new {
  my ($class, $arg, $rx) = @_;
  Carp::croak "$class does not take check arguments" if %$arg;
  bless { rx => $rx } => $class;
}

1;
