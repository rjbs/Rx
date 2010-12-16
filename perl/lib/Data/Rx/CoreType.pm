use strict;
use warnings;
package Data::Rx::CoreType;
# ABSTRACT: base class for core Rx types

use Carp ();
use Data::Rx::Failure;

sub new_checker {
  my ($class, $arg, $rx) = @_;
  Carp::croak "$class does not take check arguments" if %$arg;
  bless { rx => $rx } => $class;
}

sub rx { $_[0]->{rx} }

sub check {
  my ($self, $value) = @_;
  local $@;

  return 1 if eval { $self->validate($value); };
  my $failure = $@;

  if (eval { $failure->isa('Data::Rx::Failure') }) {
    $self->failure($failure);
    return 0;
  }

  die $failure;
}

sub fail {
  my ($self, $struct) = @_;

  $struct->{type} ||= $self->type_uri;

  die Data::Rx::Failure->new({
    rx     => $self->rx,
    struct => $struct,
  });
}

sub failure {
  my $self = shift;

  $self->{failure} = $_[0] if @_;

  return $self->{failure};
}

sub _subcheck {
  my ($self, $value, $checker, $context) = @_;

  return if eval { $checker->validate($value) };

  my $failure = $@;
  Carp::confess($failure) unless eval { $failure->isa('Data::Rx::Failure') };

  $failure->contextualize({
    type  => $self->type_uri,
    %$context,
  });

  die $failure;
}

sub type_uri {
  sprintf 'tag:codesimply.com,2008:rx/core/%s', $_[0]->subname
}

1;
