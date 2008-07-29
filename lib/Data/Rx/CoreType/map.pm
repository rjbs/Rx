use strict;
use warnings;
package Data::Rx::CoreType::map;
use base 'Data::Rx::CoreType';

use Scalar::Util ();

sub authority { '' }
sub type      { 'map' }

sub new {
  my ($class, $arg) = @_;
  Carp::croak("no contents hash given")
    unless $arg->{contents} and (ref $arg->{contents} eq 'HASH');
  Carp::croak("unknown arguments to new") unless keys %$arg == 1;

  my %content_check;
  
  for my $key (keys %{ $arg->{contents} }) {
    my %key_arg  = %{ $arg->{contents}{$key} };
    my $optional = delete $key_arg{optional};

    $content_check{ $key } = {
      optional => $optional, 
      checker  => Data::Rx->new->make_checker(\%key_arg),
    };
  };

  return bless { content_check => \%content_check } => $class;
}

sub check {
  my ($self, $value) = @_;

  return unless
    ! Scalar::Util::blessed($value) and ref $value eq 'HASH';
  
  my $c_check = $self->{content_check};
  return unless Data::Rx::Util->_x_subset_keys_y($value, $c_check);

  for my $key (keys %$c_check) {
    return if not $c_check->{$key}{optional} and not exists $value->{$key};
    return unless $c_check->{$key}{checker}->($value->{$key});
  }

  return 1;
}

1;
