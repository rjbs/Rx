use strict;
use warnings;
package Data::Rx::CoreType::all;
use base 'Data::Rx::CoreType';
# ABSTRACT: the Rx //all type
use Data::Rx::Failure;

use Scalar::Util ();

sub new_checker {
  my ($class, $arg, $rx) = @_;

  Carp::croak("unknown arguments to new")
    unless Data::Rx::Util->_x_subset_keys_y($arg, { of  => 1});

  my $self = bless { } => $class;

  Carp::croak("no 'of' parameter given to //all") unless exists $arg->{of};

  my $of = $arg->{of};

  Carp::croak("invalid 'of' argument to //all") unless
    defined $of and Scalar::Util::reftype $of eq 'ARRAY' and @$of;
    
  $self->{of} = [ map {; $rx->make_schema($_) } @$of ];

  return $self;
}

sub check {
  my ($self, $value) = @_;

  for my $sub (@{ $self->{of} }) {
      my $ok=$sub->check($value);
      return Data::Rx::Failure->new($self,{
          message => 'not all constraints matched',
          sub_failures=>[$ok],
          value => $value,
      }) if !$ok;
  }
  return 1;
}

sub subname   { 'all' }

1;
