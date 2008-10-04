use strict;
use warnings;
package Data::Rx::CoreType::num;
use base 'Data::Rx::CoreType';
# ABSTRACT: the Rx //num type

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

sub new_checker {
  my ($class, $arg, $rx) = @_;
  my $self = {};

  Carp::croak("unknown arguments to new")
    unless Data::Rx::Util->_x_subset_keys_y($arg, { range => 1, value => 1});

  $self->{range_check} = Data::Rx::Util->_make_range_check($arg->{range})
    if $arg->{range};

  if (
    exists $arg->{value}
    and (
      (! defined $arg->{value})
      or ref $arg->{value}
      or ($arg->{value} !~ $class->_val_re)
    )
  ) {
    Carp::croak(sprintf 'invalid value for %s', $class->type_name)
  }

  $self->{value} = $arg->{value} if defined $arg->{value};

  bless $self => $class;
}

sub check {
  my ($self, $value) = @_;

  return unless defined $value and length $value;

  # XXX: This is insufficiently precise.  It's here to keep us from believing
  # that JSON::XS::Boolean objects, which end up looking like 0 or 1, are
  # integers. -- rjbs, 2008-07-24
  return if ref $value;

  return unless $value =~ $self->_val_re;
  return if $self->{range_check} && ! $self->{range_check}->($value);
  return if defined($self->{value}) && $value != $self->{value};
  return 1;
}

sub subname   { 'num' }

1;
