use strict;
use warnings;
package Data::Rx::CoreType::mapall;
use base 'Data::Rx::CoreType';

use Scalar::Util ();

sub authority { '' }
sub subname   { 'mapall' }

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
