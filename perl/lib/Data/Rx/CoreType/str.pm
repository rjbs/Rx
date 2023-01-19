use v5.12.0;
use warnings;
package Data::Rx::CoreType::str;
# ABSTRACT: the Rx //str type

use parent 'Data::Rx::CoreType';

use Data::Rx::Util;

sub guts_from_arg {
  my ($class, $arg, $rx, $type) = @_;

  Carp::croak("unknown arguments to new")
    unless Data::Rx::Util->_x_subset_keys_y($arg, { length => 1, value => 1});

  # XXX: We should be able to reject num values, too. :( -- rjbs, 2008-08-25
  if (exists $arg->{value}) {
    my $val = $arg->{value};
    if (
      (! defined $val)
      or ref $val
    ) {
      Carp::croak(sprintf(
        'invalid value (%s) for //str',
        $val // 'undef',
      ));
    }
  }

  my $guts = {};

  $guts->{length_check} = Data::Rx::Util->_make_range_check($arg->{length})
    if $arg->{length};

  $guts->{value} = $arg->{value} if defined $arg->{value};

  return $guts;
}

sub assert_valid {
  my ($self, $value) = @_;

  unless (defined $value) {
    $self->fail({
      error   => [ qw(type) ],
      message => "found value is undef",
      value   => $value,
    });
  }

  # XXX: This is insufficiently precise.  It's here to keep us from believing
  # that JSON::XS::Boolean objects, which end up looking like 0 or 1, are
  # integers. -- rjbs, 2008-07-24
  if (ref $value) {
    $self->fail({
      error   => [ qw(type) ],
      message => "found value is a reference",
      value   => $value,
    });
  }

  if ($self->{length_check} && ! $self->{length_check}->(length $value)) {
    $self->fail({
      error   => [ qw(length) ],
      message => "length of value is outside allowed range",
      value   => $value,
    });
  }

  if (defined $self->{value} and $self->{value} ne $value) {
    $self->fail({
      error   => [ qw(value) ],
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
