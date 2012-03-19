use strict;
use warnings;
package Data::Rx::CoreType::arr;
use base 'Data::Rx::CoreType';
# ABSTRACT: the Rx //arr type
use Data::Rx::Failure;

use Scalar::Util ();

sub subname   { 'arr' }

sub new_checker {
  my ($class, $arg, $rx) = @_;
  my $self = $class->SUPER::new_checker({}, $rx);

  Carp::croak("no contents schema given")
    unless $arg->{contents} and (ref $arg->{contents} || 'HASH' eq 'HASH');

  Carp::croak("unknown arguments to new")
    unless Data::Rx::Util->_x_subset_keys_y($arg, {length=>1, contents=>1});

  my $content_check = $rx->make_schema($arg->{contents});

  $self->{content_check} = $content_check;

  $self->{length_check} = Data::Rx::Util->_make_range_check($arg->{length})
    if $arg->{length};

  bless $self => $class;
}

sub check {
  my ($self, $value) = @_;

  return Data::Rx::Failure->new($self,{
      message => 'not a defined value',
      value=>$value,
  })
      unless defined $value;

  return Data::Rx::Failure->new($self,{
      message => "<$value> is not an array",
      value=>$value
  }) unless
    ! Scalar::Util::blessed($value) and ref $value eq 'ARRAY';

  return Data::Rx::Failure->new($self,{
      message => 'wrong array length '.@$value,
      subtype=>'length',value=>$value,
  })
      if $self->{length_check} and ! $self->{length_check}->(0+@$value);

  my $pos=0;
  for my $item (@$value) {
      my $sub = $self->{content_check}->check($item);
      return Data::Rx::Failure->new($self,{
          message => "bad value at array position $pos",
          sub_failures=>[$sub],
          value => $value,
          pos=>$pos,
      })
          unless $sub;
      ++$pos;
  }

  return 1;
}

1;
