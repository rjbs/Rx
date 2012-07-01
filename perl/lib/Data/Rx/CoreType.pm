use strict;
use warnings;
package Data::Rx::CoreType;
# ABSTRACT: base class for core Rx types
use parent 'Data::Rx::CommonType::EasyNew';

use Carp ();

sub new_checker {
  my ($class, $arg, $rx, $type) = @_;
  Carp::croak "$class does not take check arguments" if %$arg;
  bless { type => $type, rx => $rx } => $class;
}

sub type { $_[0]->{type} }

sub rx { $_[0]->{rx} }

sub type_uri {
  sprintf 'tag:codesimply.com,2008:rx/core/%s', $_[0]->subname
}

1;
