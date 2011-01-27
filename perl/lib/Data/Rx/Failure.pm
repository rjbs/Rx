use strict;
use warnings;
package Data::Rx::Failure;
# ABSTRACT: structured failure report from an Rx checker


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

sub keys {
  my ($self) = @_;

  return @{ $self->struct->[0]{keys} || [] };
}

sub size {
  my ($self) = @_;

  return $self->struct->[0]{size};
}

sub data_path {
  my ($self) = @_;

  map @{ $_->{data} || [] }, reverse @{ $self->struct };
}

sub data_path_type {
  my ($self) = @_;

  map @{ $_->{data_type} || [] }, reverse @{ $self->struct };
}

sub data_string {
  my ($self) = @_;

  return $self->path_string('$data', [$self->data_path], [$self->data_path_type]);
}

sub check_path {
  my ($self) = @_;

  map @{ $_->{check} || [] }, reverse @{ $self->struct };
}

sub check_path_type {
  my ($self) = @_;

  map @{ $_->{check_type} || [] }, reverse @{ $self->struct };
}

sub check_string {
  my ($self) = @_;

  return $self->path_string('$schema', [$self->check_path], [$self->check_path_type]);
}

sub path_string {
  my ($self, $base, $path, $type) = @_;

  my $str = $base;

  if (@$path) {
    $str .= '->';
    for (my $i = 0; $i < @$path; ++$i) {
      $str .= $type->[$i] eq 'i' ? "[$path->[$i]]" : "{$path->[$i]}";
    }
  }

  return $str;
}

sub stringify {
  my ($self) = @_;

  my $struct = $self->struct;

  return "Failed $struct->[0]{type}: $struct->[0]{message} " .
         "(error: " . $self->error_string . " " .
         "at " . $self->data_string . ")\n";
}

1;
