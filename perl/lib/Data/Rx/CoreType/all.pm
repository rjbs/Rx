use strict;
use warnings;
package Data::Rx::CoreType::all;
use base 'Data::Rx::CoreType';

use Scalar::Util ();

sub new {
  my ($class, $arg, $rx) = @_;

  Carp::croak("unknown arguments to new")
    unless Data::Rx::Util->_x_subset_keys_y($arg, { of  => 1});

  my $self = bless { } => $class;

  if (my $of = $arg->{of}) {
    Carp::croak("invalid 'of' argument to //all") unless
      Scalar::Util::reftype $of eq 'ARRAY' and @$of;
    
    $self->{of} = [ map {; $rx->make_schema($_) } @$of ];
  }

  return $self;
}

sub check {
  my ($self, $value) = @_;
  
  $_->check($value) || return for @{ $self->{of} };
  return 1;
}

sub authority { '' }
sub subname   { 'all' }

1;
