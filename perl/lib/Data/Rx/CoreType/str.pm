use strict;
use warnings;
package Data::Rx::CoreType::str;
use base 'Data::Rx::CoreType';
# ABSTRACT: the Rx //str type

use Data::Rx::Util;

sub new_checker {
  my ($class, $arg, $rx) = @_;
  my $self = {};

  Carp::croak("unknown arguments to new")
    unless Data::Rx::Util->_x_subset_keys_y($arg, { length => 1, value => 1});

  # XXX: We should be able to reject num values, too. :( -- rjbs, 2008-08-25
  Carp::croak(sprintf 'invalid value for %s', $class->type_name)
    if exists $arg->{value} and (ref $arg->{value} or ! defined $arg->{value});

  $self->{length_check} = Data::Rx::Util->_make_range_check($arg->{length})
    if $arg->{length};

  $self->{value} = $arg->{value} if defined $arg->{value};

  bless $self => $class;
}

sub check {
  my ($self, $value) = @_;

  return unless defined $value;

  # XXX: This is insufficiently precise.  It's here to keep us from believing
  # that JSON::XS::Boolean objects, which end up looking like 0 or 1, are
  # integers. -- rjbs, 2008-07-24
  return if ref $value;

  return if $self->{length_check} && ! $self->{length_check}->(length $value);

  return if defined $self->{value} and $self->{value} ne $value;

  # XXX: Really, we need a way to know whether (say) the JSON was one of the
  # following:  { "foo": 1 } or { "foo": "1" }
  # Only one of those is providing a string. -- rjbs, 2008-07-27
  return 1;
}

sub subname   { 'str' }

1;
