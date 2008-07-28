package Data::Rx::CoreType::num;
use Mouse;

sub _int_re { qr{(?:0|[1-9]\d*)} }
sub _dec_re { qr{(?:\.\d+)?}     }
sub _exp_re { my $int_re = $_[0]->_int_re; qr{(?:e$int_re)?}i }

sub _val_re {
  my ($self) = @_;

  return '\A'
       . qr{[-+]?}
       . join(q{}, map {; $self->$_ } qw(_int_re _dec_re _exp_re))
       . '\z';
}

sub check {
  my ($self, $value) = @_;

  return unless defined $value and length $value;

  # XXX: This is insufficiently precise.  It's here to keep us from believing
  # that JSON::XS::Boolean objects, which end up looking like 0 or 1, are
  # integers. -- rjbs, 2008-07-24
  return if ref $value;

  return unless $value =~ $self->_val_re;
  return 1;
}

sub authority { '' }
sub type      { 'num' }

__PACKAGE__->meta->make_immutable;
no Mouse;
1;
