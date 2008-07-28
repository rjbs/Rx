use strict;
use warnings;
package Data::Rx::CoreType::seq;
use base 'Data::Rx::CoreType';

use Scalar::Util ();

sub authority { '' }
sub type      { 'seq' }

sub new {
  my ($class, $arg) = @_;

  Carp::croak("no contents array given")
    unless $arg->{contents} and (ref $arg->{contents} eq 'ARRAY');

  Carp::croak("unknown arguments to new")
    unless Data::Rx::Util->_x_subset_keys_y($arg, {contents=>1,tail=>1});

  my @content_checks = map { Data::Rx->new->make_checker($_) }
                      @{ $arg->{contents} };

  my $self = {
    content_checks => \@content_checks,
    tail_check     => $arg->{tail}
                    ? Data::Rx->new->make_checker($arg->{tail})
                    : undef
  };

  bless $self => $class;
}

sub check {
  my ($self, $value) = @_;

  return unless
    ! Scalar::Util::blessed($value) and ref $value eq 'ARRAY';

  my $content_checks = $self->{content_checks};
  return if @$value < @$content_checks;
  
  for my $i (0 .. $#$content_checks) {
    return unless $content_checks->[ $i ]->( $value->[ $i ] );
  }

  if ($self->{tail_check} and @$value > @$content_checks) {
    my $tail = [ @$value[ @$content_checks..$#$value ] ];
    return unless $self->{tail_check}->($tail);
  }

  return 1;
}

1;
