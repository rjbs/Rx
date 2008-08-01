use strict;
use warnings;
package Data::Rx::CoreType::str;
use base 'Data::Rx::CoreType';

sub check {
  my ($self, $value) = @_;

  return unless defined $value;

  # XXX: This is insufficiently precise.  It's here to keep us from believing
  # that JSON::XS::Boolean objects, which end up looking like 0 or 1, are
  # integers. -- rjbs, 2008-07-24
  return if ref $value;

  # XXX: Really, we need a way to know whether (say) the JSON was one of the
  # following:  { "foo": 1 } or { "foo": "1" }
  # Only one of those is providing a string. -- rjbs, 2008-07-27
  return 1;
}

sub authority { '' }
sub subname   { 'str' }

1;
