use strict;
use warnings;
package Data::Rx::Failure;
# ABSTRACT: class for Rx failures

use overload '""' => \&stringify;

sub new {
  my ($class, $arg) = @_;

  my $guts = {
    rx => $arg->{rx},
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

sub value {
  my ($self) = @_;

  return $self->struct->[0]{value};
}

sub error_types {
  my ($self) = @_;

  return @{ $self->struct->[0]{error} };
}

sub error_string {
  my ($self) = @_;

  join ', ', $self->error_types;
}

sub data_path {
  my ($self) = @_;

  map @{ $_->{data} || [] }, reverse @{ $self->struct };
}

sub data_string {
  my ($self) = @_;

  my @data_path = $self->data_path;

  return '$data' . (@data_path ? '->' . join('', map "{$_}", @data_path) : '');
}

sub check_path {
  my ($self) = @_;

  map @{ $_->{check} || [] }, reverse @{ $self->struct };
}

sub check_string {
  my ($self) = @_;

  my @check_path = $self->check_path;

  return '$schema' . (@check_path ? '->' . join('', map "{$_}", @check_path) : '');
}

sub stringify {
  my ($self) = @_;

  my $struct = $self->struct;

  return "Failed $struct->[0]{type}: $struct->[0]{message} " .
         "(error: " . $self->error_string . " " .
         "at " . $self->data_string . ")\n";
}

1;
