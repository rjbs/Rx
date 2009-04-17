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
    unless Data::Rx::Util->_x_subset_keys_y($arg, { value => 1});

  # XXX: We should be able to reject num values, too. :( -- rjbs, 2008-08-25
  Carp::croak(sprintf 'invalid value for %s', $class->type_name)
    if exists $arg->{value} and (ref $arg->{value} or ! defined $arg->{value});

  $self->{value} = $arg->{value} if defined $arg->{value};

  bless $self => $class;
}

sub validate {
  my ($self, $value) = @_;

  unless (defined $value) {
    $self->fail({
      type    => [ qw(type) ],
      message => "found value is undef",
      value   => $value,
    });
  }

  # XXX: This is insufficiently precise.  It's here to keep us from believing
  # that JSON::XS::Boolean objects, which end up looking like 0 or 1, are
  # integers. -- rjbs, 2008-07-24
  if (ref $value) {
    $self->fail({
      type    => [ qw(type) ],
      message => "found value is a reference",
      value   => $value,
    });
  }

  if (defined $self->{value} and $self->{value} ne $value) {
    $self->fail({
      type    => [ ], # ??? -- rjbs, 2009-04-15
      message => "found value is not the required value",
      value   => $value,
    });
  }

  # XXX: Really, we need a way to know whether (say) the JSON was one of the
  # following:  { "foo": 1 } or { "foo": "1" }
  # Only one of those is providing a string. -- rjbs, 2008-07-27
  return 1;
}

sub subname   { 'str' }

1;
