use strict;
use warnings;
package Data::Rx::Util;
use Carp ();

sub _x_subset_keys_y {
  my ($self, $x, $y) = @_;

  return unless keys %$x <= keys %$y;

  for my $key (keys %$x) {
    return unless exists $y->{$key};
  }

  return 1;
}

sub _make_length_check {
  my ($self, $arg) = @_;
  
  Carp::croak "no arguments given" unless $arg and keys %$arg;
  Carp::croak "unknown arguments" unless $self->_x_subset_keys_y(
    $arg, { map {; $_ => 1 } qw(min max) },
  );

  for my $field (grep { exists $arg->{$_} } qw(min max)) {
    Carp::croak "illegal $field"
      if $arg->{$field} < 0 or int($arg->{$field}) != $arg->{$field};
  }

  Carp::croak "min exceeds max"
    if exists $arg->{min} and exists $arg->{max} and $arg->{min} > $arg->{max};

  return sub { $_[0] >= $arg->{min} and $_[0] <= $arg->{max} }
    if exists $arg->{min} and exists $arg->{max};

  return sub { $_[0] >= $arg->{min} } if exists $arg->{min};
  return sub { $_[0] <= $arg->{max} } if exists $arg->{max};
  
  Carp::confess "should never reach here";
}

1;
