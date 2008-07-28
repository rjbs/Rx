use strict;
use warnings;
package Data::Rx::CoreType::map;
use base 'Data::Rx::CoreType';

use Scalar::Util ();

sub authority { '' }
sub type      { 'map' }

sub new {
  my ($class, $arg) = @_;
  Carp::croak("no contents hash given")   unless $arg->{contents};
  Carp::croak("unknown arguments to new") unless keys %$arg == 1;

  my %content_check = (
    map {; $_ => Data::Rx->new->make_checker($arg->{contents}{$_}) }
        keys %{ $arg->{contents} }
  );

  return bless { content_check => \%content_check } => $class;
}

sub check {
  my ($self, $value) = @_;

  return unless
    ! Scalar::Util::blessed($value) and ref $value eq 'HASH';
  
  my %c_check = %{ $self->{content_check} };
  return unless keys %$value == keys %c_check;

  for my $key (keys %c_check) {
    return unless exists $value->{$key} and $c_check{$key}->($value->{$key});
  }

  return 1;
}

1;
