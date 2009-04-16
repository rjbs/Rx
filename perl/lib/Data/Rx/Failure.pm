use strict;
use warnings;
package Data::Rx::Failure;
# ABSTRACT: a structured failure report from an Rx checker

sub new {
  my ($class, $arg) = @_;
  my $guts = {
    rx     => $arg->{rx},
    struct => [ $arg->{struct} ],
  };

  bless $guts => $class;
}

sub struct { $_[0]->{struct} }

sub contextualize {
  my ($self, $struct) = @_;

  push @{ $self->struct }, $struct;

  return $self;
}

1;
