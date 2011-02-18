use strict;
use warnings;
package Data::Rx::CoreType::arr;
use base 'Data::Rx::CoreType';
# ABSTRACT: the Rx //arr type

use Scalar::Util ();

sub subname   { 'arr' }

sub new_checker {
  my ($class, $arg, $rx) = @_;

  Carp::croak("unknown arguments to new")
    unless Data::Rx::Util->_x_subset_keys_y($arg, {length=>1, contents=>1,
                                                   skip=>1});

  Carp::croak("no contents schema given")
    unless $arg->{contents} and (ref $arg->{contents} || 'HASH' eq 'HASH');

  my $self = $class->SUPER::new_checker({}, $rx);

  my $content_check = $rx->make_schema($arg->{contents});

  $self->{content_check} = $content_check;

  $self->{length_check} = Data::Rx::Util->_make_range_check($arg->{length})
    if $arg->{length};

  $self->{skip} = $arg->{skip} || 0;

  return $self;
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

  my @subchecks;

  if ($self->{length_check} and
      ! $self->{length_check}->(@$value - $self->{skip})) {
    push @subchecks,
      $self->new_fail({
        error   => [ qw(size) ],
        size    => 0 + @$value,  # note: actual size, not size - skip
        message => "number of entries is outside permitted range",
        value   => $value,
      });
  }
  
  for my $i ($self->{skip} .. $#$value) {
    push @subchecks, [
                      $value->[$i],
                      $self->{content_check},
                      { data       => [$i ],
                        data_type  => ['i'],
                        check      => ['contents'],
                        check_type => ['k'       ],
                      },
                     ];
  }

  $self->_subchecks(\@subchecks);

  return 1;
}

1;
