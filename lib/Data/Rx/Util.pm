use strict;
use warnings;
package Data::Rx::Util;
use Carp ();
use List::Util ();
use Number::Tolerant ();

sub _x_subset_keys_y {
  my ($self, $x, $y) = @_;

  return unless keys %$x <= keys %$y;

  for my $key (keys %$x) {
    return unless exists $y->{$key};
  }

  return 1;
}

sub _make_range_check {
  my ($self, $mk_arg, $arg) = @_;

  my $var = {
    allow_negative  => 1,
    allow_fraction  => 1,
    allow_exclusive => 1,
    %$mk_arg,
  };
  
  Carp::croak "no arguments given" unless $arg and keys %$arg;

  my @keys = $var->{allow_exclusive} ? qw(min min-ex max-ex max) : qw(min max);

  Carp::croak "unknown arguments" unless $self->_x_subset_keys_y(
    $arg,
    { map {; $_ => 1 } @keys },
  );

  for my $field (grep { exists $arg->{$_} } @keys) {
    Carp::croak "illegal $field: must be non-negative"
      if !$var->{allow_negative} and $arg->{$field} < 0;

    Carp::croak "illegal $field: must be integer"
      if !$var->{allow_fraction} and int($arg->{$field}) != $arg->{$field};
  }

  my @tolerances;
  push @tolerances, Number::Tolerant->new($arg->{min} => 'or_more')
    if exists $arg->{min};
  push @tolerances, Number::Tolerant->new(more_than => $arg->{'min-ex'})
    if exists $arg->{'min-ex'};
  push @tolerances, Number::Tolerant->new($arg->{max} => 'or_less')
    if exists $arg->{max};
  push @tolerances, Number::Tolerant->new(less_than => $arg->{'max-ex'})
    if exists $arg->{'max-ex'};
  
  my $tol = do {
    no warnings 'once';
    List::Util::reduce { $a & $b } @tolerances;
  };
  
  return sub { $_[0] == $tol };
}

1;
