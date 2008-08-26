use strict;
use warnings;
package Data::Rx::CoreType;

sub new {
  my ($class, $arg, $rx) = @_;
  Carp::croak "$class does not take check arguments" if %$arg;
  bless { rx => $rx } => $class;
}

sub type_name {
  sprintf '/%s/%s', $_[0]->authority, $_[0]->subname
}

1;
