use strict;
use warnings;
package Data::Rx::CoreType::int;
use base 'Data::Rx::CoreType::num';

sub authority { '' }
sub subname   { 'int' }

sub new {
  my ($class, $arg, $rx) = @_;
  my $self = {};

  Carp::croak("unknown arguments to new")
    unless Data::Rx::Util->_x_subset_keys_y($arg, {range=>1});

  if ($arg->{range}) {
    $self->{range_check} = Data::Rx::Util->_make_range_check(
      {
        allow_negative  => 1,
        allow_fraction  => 0,
        allow_exclusive => 1,
      },
      $arg->{range},
    );
  }

  bless $self => $class;
}

sub check {
  my ($self, $value) = @_;
  return unless $self->SUPER::check($value);
  return unless $value == int $value;
  return if $self->{range_check} && ! $self->{range_check}->($value);
  return 1;
}

1;
