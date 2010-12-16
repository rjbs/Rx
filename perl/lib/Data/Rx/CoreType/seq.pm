use strict;
use warnings;
package Data::Rx::CoreType::seq;
use base 'Data::Rx::CoreType';
# ABSTRACT: the Rx //seq type

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

sub validate {
  my ($self, $value) = @_;

  unless (! Scalar::Util::blessed($value) and ref $value eq 'ARRAY') {
    $self->fail({
      error   => [ qw(type) ],
      message => "found value is not an arrayref",
      value   => $value,
    });
  }

  my $content_schemata = $self->{content_schemata};
  if (@$value < @$content_schemata) {
    $self->fail({
      error   => [ qw(size) ],
      value   => $value,
      check   => ['contents'],
      message => sprintf(
        "too few entries found; found %s, need at least %s",
        0 + @$value,
        0 + @$content_schemata,
      ),
    });
  }

  for my $i (0 .. $#$content_schemata) {
    $self->_subcheck(
      $value->[ $i ],
      $content_schemata->[ $i ],
      { data => [$i],
        check => ['contents', $i],
      },
    );
  }

  if (@$value > @$content_schemata) {
    if ($self->{tail_check}) {
      my $tail = [ @$value[ @$content_schemata..$#$value ] ];
      $self->_subcheck(
        $tail,
        $self->{tail_check},
        { check => ['tail'] },
      );
    } else {
      $self->fail({
        error   => [ qw(size) ],
        value   => $value,
        check   => ['contents'],
        message => sprintf(
          "too many entries found; found %s, need no more than %s",
          0 + @$value,
          0 + @$content_schemata,
        ),
      });
    }
  }   

  return 1;
}

1;
