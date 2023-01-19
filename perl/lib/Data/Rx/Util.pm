use v5.12.0;
use warnings;
package Data::Rx::Util;
# ABSTRACT: helper routines for Data::Rx

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
  my ($self, $arg) = @_;

  my @keys = qw(min min-ex max-ex max);

  Carp::croak "unknown arguments" unless $self->_x_subset_keys_y(
    $arg,
    { map {; $_ => 1 } @keys },
  );

  return sub { 1 } unless keys %$arg;

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
