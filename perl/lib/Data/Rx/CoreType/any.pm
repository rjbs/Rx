use v5.12.0;
use warnings;
package Data::Rx::CoreType::any;
# ABSTRACT: the Rx //any type

use parent 'Data::Rx::CoreType';

use Scalar::Util ();

sub guts_from_arg {
  my ($class, $arg, $rx, $type) = @_;

  Carp::croak("unknown arguments to new")
    unless Data::Rx::Util->_x_subset_keys_y($arg, { of  => 1});

  my $guts = {};

  if (my $of = $arg->{of}) {
    Carp::croak("invalid 'of' argument to //any") unless
      Scalar::Util::reftype $of eq 'ARRAY' and @$of;

    $guts->{of} = [ map {; $rx->make_schema($_) } @$of ];
  }

  return $guts;
}

sub assert_valid {
  return 1 unless $_[0]->{of};

  my ($self, $value) = @_;

  my @failures;
  for my $i (0 .. $#{ $self->{of} }) {
    my $check = $self->{of}[ $i ];
    return 1 if eval { $check->assert_valid($value) };

    my $failure = $@;
    $failure->contextualize({
      type       => $self->type,
      check_path => [ [ 'of', 'key'], [ $i, 'index' ] ],
    });

    push @failures, $failure;
  }

  $self->fail({
    error    => [ qw(none) ],
    message  => "matched none of the available alternatives",
    value    => $value,
    failures => \@failures,
  });
}

sub subname   { 'any' }

1;
