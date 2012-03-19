use strict;
use warnings;
package Data::Rx::CoreType::map;
use base 'Data::Rx::CoreType';
# ABSTRACT: the Rx //map type
use Data::Rx::Failure;

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

sub check {
  my ($self, $value) = @_;

  return Data::Rx::Failure->new($self,{
      message => 'not a defined value',
      value=>$value,
  })
      unless defined $value;

  return Data::Rx::Failure->new($self,{
      message => "<$value> is not a hashref",
      value=>$value,
  }) unless
    ! Scalar::Util::blessed($value) and ref $value eq 'HASH';

  for my $entry_key (keys %$value) {
      my $entry_value = $value->{$entry_key};
      my $sub = $self->{value_constraint}->check($entry_value);
      return Data::Rx::Failure->new($self,{
          message => "bad value in map for key <$entry_key>",
          sub_failures=>[$sub],
          value => $value,
          key=>$entry_key,
      })
          unless $sub;
  }

  return 1;
}

1;
