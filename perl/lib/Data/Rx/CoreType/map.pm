use v5.12.0;
use warnings;
package Data::Rx::CoreType::map;
# ABSTRACT: the Rx //map type

use parent 'Data::Rx::CoreType';

use Scalar::Util ();

sub subname   { 'map' }

sub guts_from_arg {
  my ($class, $arg, $rx, $type) = @_;

  Carp::croak("unknown arguments to new") unless
    Data::Rx::Util->_x_subset_keys_y($arg, { values => 1 });

  Carp::croak("no values constraint given") unless $arg->{values};

  return { value_constraint => $rx->make_schema($arg->{values}) };
}

sub assert_valid {
  my ($self, $value) = @_;

  unless (! Scalar::Util::blessed($value) and ref $value eq 'HASH') {
    $self->fail({
      error   => [ qw(type) ],
      message => "found value is not a hashref",
      value   => $value,
    });
  }

  my @subchecks;
  for my $key ($self->rx->sort_keys ? sort keys %$value : keys %$value) {
    push @subchecks, [
      $value->{ $key },
      $self->{value_constraint},
      { data_path  => [ [$key, 'key'] ],
        check_path => [ ['values', 'key' ] ],
      },
    ];
  }

  $self->perform_subchecks(\@subchecks);

  return 1;
}

1;
