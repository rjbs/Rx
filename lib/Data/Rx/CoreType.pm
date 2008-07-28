use strict;
use warnings;
package Data::Rx::CoreType;

sub new {
  my ($class, $arg) = @_;
  Carp::croak "$class does not take check arguments" if %$arg;
  bless {} => $class;
}

1;
