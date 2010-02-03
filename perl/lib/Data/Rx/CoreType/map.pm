use strict;
use warnings;
package Data::Rx::CoreType::map;
use base 'Data::Rx::CoreType';
# ABSTRACT: the Rx //map type

use Scalar::Util ();

sub subname   { 'map' }

sub new_checker {
  my ($class, $arg, $rx) = @_;
  my $self = $class->SUPER::new_checker({}, $rx);

  Carp::croak("unknown arguments to new") unless
  Data::Rx::Util->_x_subset_keys_y($arg, { values => 1 });

  my $content_schema = {};

  Carp::croak("no values constraint given") unless $arg->{values};

  $self->{value_constraint} = $rx->make_schema($arg->{values});

  return $self;
}

sub validate {
  my ($self, $value) = @_;

  unless (! Scalar::Util::blessed($value) and ref $value eq 'HASH') {
    $self->fail({
      error   => [ qw(type) ],
      message => "found value is not a hashref",
      value   => $value,
    });
  }

  for my $key (keys %$value) {
    $self->_subcheck(
      $value->{ $key },
      $self->{value_constraint},
      {
        entry    => $key,
      },
    );
  }

  return 1;
}

1;
