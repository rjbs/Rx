use strict;
use warnings;
package Data::Rx::CoreType::all;
use base 'Data::Rx::CoreType';
# ABSTRACT: the Rx //all type

use Scalar::Util ();

sub new_checker {
  my ($class, $arg, $rx, $type) = @_;

  Carp::croak("unknown arguments to new")
    unless Data::Rx::Util->_x_subset_keys_y($arg, { of  => 1});

  my $self = $class->SUPER::new_checker({}, $rx, $type);

  Carp::croak("no 'of' parameter given to //all") unless exists $arg->{of};

  my $of = $arg->{of};

  Carp::croak("invalid 'of' argument to //all") unless
    defined $of and Scalar::Util::reftype $of eq 'ARRAY' and @$of;

  $self->{of} = [ map {; $rx->make_schema($_) } @$of ];

  return $self;
}

sub validate {
  my ($self, $value) = @_;

  my @subchecks;
  for my $i (0 .. $#{ $self->{of} }) {
    push @subchecks, [
      $value,
      $self->{of}[$i],
      { check      => ['of', $i ],
        check_type => ['k' , 'i'],
      },
    ];
  }

  $self->_subchecks(\@subchecks);

  return 1;
}

sub subname   { 'all' }

1;
