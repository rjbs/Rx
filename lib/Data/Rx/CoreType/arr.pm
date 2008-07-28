use strict;
use warnings;
package Data::Rx::CoreType::arr;
use base 'Data::Rx::CoreType';

use Scalar::Util ();

sub authority { '' }
sub type      { 'arr' }

sub new {
  my ($class, $arg) = @_;

  Carp::croak("no contents hash given")
    unless $arg->{contents} and (ref $arg->{contents} eq 'HASH');

  Carp::croak("unknown arguments to new")
    unless Data::Rx::Util->_x_subset_keys_y($arg, {length=>1, contents=>1});

  my $content_check = Data::Rx->new->make_checker($arg->{contents});

  my $self = {
    content_check => $content_check,
    length_check  => $arg->{length}
                  ?  Data::Rx::Util->_make_length_check($arg->{length})
                  :  undef,
  };

  bless $self => $class;
}

sub check {
  my ($self, $value) = @_;

  return unless
    ! Scalar::Util::blessed($value) and ref $value eq 'ARRAY';

  return if $self->{length_check} and ! $self->{length_check}->(0+@$value);
  
  for my $item (@$value) {
    return unless $self->{content_check}->($item);
  }

  return 1;
}

1;
