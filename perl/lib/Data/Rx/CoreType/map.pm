use strict;
use warnings;
package Data::Rx::CoreType::map;
use base 'Data::Rx::CoreType';
# ABSTRACT: Rx '//map' type

use Scalar::Util ();

sub subname   { 'map' }

sub new {
  my ($class, $arg, $rx) = @_;
  my $self = $class->SUPER::new({}, $rx);

  Carp::croak("unknown arguments to new") unless
  Data::Rx::Util->_x_subset_keys_y($arg, { values => 1 });

  my $content_schema = {};

  Carp::croak("no values constraint given") unless $arg->{values};

  $self->{value_constraint} = $rx->make_schema($arg->{values});

  return $self;
}

sub check {
  my ($self, $value) = @_;

  return unless
    ! Scalar::Util::blessed($value) and ref $value eq 'HASH';

  for my $entry_value (values %$value) {
    return unless $self->{value_constraint}->check($entry_value);
  }

  return 1;
}

1;
