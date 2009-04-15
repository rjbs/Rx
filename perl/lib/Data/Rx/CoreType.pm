use strict;
use warnings;
package Data::Rx::CoreType;
# ABSTRACT: base class for core Rx types

sub new_checker {
  my ($class, $arg, $rx) = @_;
  Carp::croak "$class does not take check arguments" if %$arg;
  bless { rx => $rx } => $class;
}

sub check {
  my ($self, $value) = @_;
  local $@;

  my $ok = eval { $self->validate($value); };
}

sub type_uri {
  sprintf 'tag:codesimply.com,2008:rx/core/%s', $_[0]->subname
}

1;
