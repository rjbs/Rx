use strict;
use warnings;
package Data::Rx::CoreType::arr;
use base 'Data::Rx::CoreType';
# ABSTRACT: the Rx //arr type

use Scalar::Util ();

sub subname   { 'arr' }

sub new_checker {
  my ($class, $arg, $rx) = @_;
  my $self = $class->SUPER::new_checker({}, $rx);

  Carp::croak("no contents schema given")
    unless $arg->{contents} and (ref $arg->{contents} || 'HASH' eq 'HASH');

  Carp::croak("unknown arguments to new")
    unless Data::Rx::Util->_x_subset_keys_y($arg, {length=>1, contents=>1,
                                                   skip=>1});

  my $content_check = $rx->make_schema($arg->{contents});

  $self->{content_check} = $content_check;

  $self->{length_check} = Data::Rx::Util->_make_range_check($arg->{length})
    if $arg->{length};

  $self->{skip} = $arg->{skip} || 0;

  bless $self => $class;
}

sub validate {
  my ($self, $value) = @_;

  unless (! Scalar::Util::blessed($value) and ref $value eq 'ARRAY') {
    $self->fail({
      error   => [ qw(type) ],
      message => "found value is not an arrayref",
      value   => $value,
    });
  }

  if ($self->{length_check} and
      ! $self->{length_check}->(@$value - $self->{skip})) {
    $self->fail({
      error   => [ qw(size) ],
      message => "number of entries is outside permitted range",
      value   => $value,
      check   => ['length'],
    });
  }
  
  my @subchecks;
  for my $i ($self->{skip} .. $#$value) {
    push @subchecks, [
                      $value->[$i],
                      $self->{content_check},
                      { data => [$i],
                        check => ['contents'],
                      },
                     ];
  }

  $self->_subchecks(\@subchecks);

  return 1;
}

1;
