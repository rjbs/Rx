use strict;
use warnings;
package Data::Rx::CoreType::any;
use base 'Data::Rx::CoreType';
# ABSTRACT: the Rx //any type
use Data::Rx::Failure;

use Scalar::Util ();

sub new_checker {
  my ($class, $arg, $rx) = @_;

  Carp::croak("unknown arguments to new")
    unless Data::Rx::Util->_x_subset_keys_y($arg, { of  => 1});

  my $self = bless { } => $class;

  if (my $of = $arg->{of}) {
    Carp::croak("invalid 'of' argument to //any") unless
      Scalar::Util::reftype $of eq 'ARRAY' and @$of;
    
    $self->{of} = [ map {; $rx->make_schema($_) } @$of ];
  }

  return $self;
}

sub check {
  return 1 unless $_[0]->{of};

  my ($self, $value) = @_;

  my @failures;
  for my $sub (@{ $self->{of} }) {
      my $ok=$sub->check($value);
      return 1 if $ok;
      push @failures,$ok;
  }
  return Data::Rx::Failure->new($self,{
      message => 'none of the constraints matched',
      sub_failures=>\@failures,
      value => $value,
  });
}

sub subname   { 'any' }

1;
