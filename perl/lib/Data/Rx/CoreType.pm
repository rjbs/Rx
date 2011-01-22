use strict;
use warnings;
package Data::Rx::CoreType;
# ABSTRACT: base class for core Rx types

use Carp ();
use Scalar::Util ();
use Data::Rx::Failure;
use Data::Rx::Failures;

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
  my $failures = $@;

  if (eval { $failures->isa('Data::Rx::Failures') }) {
    $self->failure($failures);
    return 0;
  }

  die $failures;
}

sub new_fail {
  my ($self, $struct) = @_;

  $struct->{type} ||= $self->type_uri;

  Data::Rx::Failures->new({
    failures => [
      Data::Rx::Failure->new({
        rx     => $self->rx,
        struct => $struct,
      })
    ]
  });
}

sub fail {
  my ($self, $struct) = @_;

  die $self->new_fail($struct);
}

sub failure {
  my $self = shift;

  $self->{failure} = $_[0] if @_;

  return $self->{failure};
}

sub _subchecks {
  my ($self, $subchecks, $fails) = @_;

  my @fails;

  foreach my $subcheck (@$subchecks) {
    if (Scalar::Util::blessed($subcheck)) {
      push @fails, $subcheck;
      next;
    }

    my ($value, $checker, $context) = @$subcheck;

    next if eval { $checker->validate($value) };

    my $failures = $@;
    Carp::confess($failures)
      unless eval { $failures->isa('Data::Rx::Failures') ||
                    $failures->isa('Data::Rx::Failure') };

    $failures->contextualize({
      type  => $self->type_uri,
      %$context,
    });

    push @fails, $failures;
  }

  if (@fails) {
    die Data::Rx::Failures->new( { failures => \@fails } );
  }

  return 1;
}

sub _subcheck {
  my ($self, $value, $checker, $context) = @_;

  return if eval { $checker->validate($value) };

  my $failures = $@;
  Carp::confess($failures)
      unless eval { $failures->isa('Data::Rx::Failures') ||
                    $failures->isa('Data::Rx::Failure') };

  $failures->contextualize({
    type  => $self->type_uri,
    %$context,
  });

  die $failures;
}

sub type_uri {
  sprintf 'tag:codesimply.com,2008:rx/core/%s', $_[0]->subname
}

1;
