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

sub path_to_check {
  my ($self) = @_;
  my @path;
  for my $frame (reverse @{ $self->{struct} }) {
    next unless exists $frame->{subcheck};
    push @path, $frame->{subcheck};
  }

  return \@path;
}

sub path_to_value {
  my ($self) = @_;

  my @path;
  for my $frame (reverse @{ $self->{struct} }) {
    next unless exists $frame->{entry};
    push @path, $frame->{entry};
  }

  return \@path;
}

1;
