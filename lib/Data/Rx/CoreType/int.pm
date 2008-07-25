use strict;
use warnings;
package Data::Rx::CoreType::int;

my $int_re = qr{(?:0|[1-9]\d*)};
my $dec_re = qr{\.0+};
my $exp_re = qr{e$int_re}i;

sub check {
  my ($self, $value) = @_;

  return unless defined $value and length $value;

  # XXX: This is insufficiently precise.  It's here to keep us from believing
  # that JSON::XS::Boolean objects, which end up looking like 0 or 1, are
  # integers. -- rjbs, 2008-07-24
  return if ref $value;

  return unless grep { B::svref_2object(\$value)->isa("B::$_") } qw(IV PV UV);
  return unless $value =~ /\A $int_re $dec_re? $exp_re? \z/x;
  return 1;
}

sub authority { '' }
sub type      { 'int' }

1;
