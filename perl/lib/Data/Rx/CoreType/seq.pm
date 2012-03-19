use strict;
use warnings;
package Data::Rx::CoreType::seq;
use base 'Data::Rx::CoreType';
# ABSTRACT: the Rx //seq type
use Data::Rx::Failure;

use Scalar::Util ();

sub subname   { 'seq' }

sub new_checker {
  my ($class, $arg, $rx) = @_;
  my $self = $class->SUPER::new_checker({}, $rx);

  Carp::croak("no contents array given")
    unless $arg->{contents} and (ref $arg->{contents} eq 'ARRAY');

  Carp::croak("unknown arguments to new")
    unless Data::Rx::Util->_x_subset_keys_y($arg, {contents=>1,tail=>1});

  my @content_schemata = map { $rx->make_schema($_) }
                         @{ $arg->{contents} };

  $self->{content_schemata} = \@content_schemata;
  $self->{tail_check} = $arg->{tail}
                      ? $rx->make_schema($arg->{tail})
                      : undef;

  return $self;
}

sub check {
  my ($self, $value) = @_;

  return Data::Rx::Failure->new($self,{
      message => 'not a defined value',
      value=>$value,
  })
      unless defined $value;

  return Data::Rx::Failure->new($self,{
      message => "<$value> is not an arrayref",
      value=>$value,
  }) unless
    ! Scalar::Util::blessed($value) and ref $value eq 'ARRAY';

  my $content_schemata = $self->{content_schemata};
  return Data::Rx::Failure->new($self,{
      message => 'sequence too short ('.@$value.
          'elements, expected at least '.@$content_schemata.')',
      subtype=>'length',
      value=>$value,
  })
      if @$value < @$content_schemata;

  for my $i (0 .. $#$content_schemata) {
      my $sub = $content_schemata->[ $i ]->check( $value->[ $i ] );
      return Data::Rx::Failure->new($self,{
          message => "bad value at sequence position $i",
          sub_failures=>[$sub],
          value => $value,
          pos=>$i,
      })
          unless $sub;
  }

  if ($self->{tail_check} and @$value > @$content_schemata) {
    my $tail = [ @$value[ @$content_schemata..$#$value ] ];
    my $sub = $self->{tail_check}->check($tail);
      return Data::Rx::Failure->new($self,{
          message => 'bad values at sequence tail',
          subtype=>'tail',
          sub_failures=>[$sub],
          value=>$value,
      })
          unless $sub;
  }

  return 1;
}

1;
