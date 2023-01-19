use v5.12.0;
use warnings;
package Data::Rx::CoreType::seq;
# ABSTRACT: the Rx //seq type

use parent 'Data::Rx::CoreType';

use Scalar::Util ();

sub subname   { 'seq' }

sub guts_from_arg {
  my ($class, $arg, $rx, $type) = @_;

  Carp::croak("unknown arguments to new")
    unless Data::Rx::Util->_x_subset_keys_y($arg, {contents=>1,tail=>1});

  Carp::croak("no contents array given")
    unless $arg->{contents} and (ref $arg->{contents} eq 'ARRAY');

  my $guts = {};

  my @content_schemata = map { $rx->make_schema($_) }
                         @{ $arg->{contents} };

  $guts->{content_schemata} = \@content_schemata;
  $guts->{tail_check} = $arg->{tail}
                      ? $rx->make_schema({ %{$arg->{tail}},
                                           skip => 0+@{$arg->{contents}}})
                      : undef;

  return $guts;
}

sub assert_valid {
  my ($self, $value) = @_;

  unless (! Scalar::Util::blessed($value) and ref $value eq 'ARRAY') {
    $self->fail({
      error   => [ qw(type) ],
      message => "found value is not an arrayref",
      value   => $value,
    });
  }

  my @subchecks;

  my $content_schemata = $self->{content_schemata};
  if (@$value < @$content_schemata) {
    push @subchecks,
      $self->new_fail({
        error   => [ qw(size) ],
        size    => 0 + @$value,
        value   => $value,
        message => sprintf(
          "too few entries found; found %s, need at least %s",
          0 + @$value,
          0 + @$content_schemata,
        ),
      });
  }

  for my $i (0 .. $#$content_schemata) {
    last if $i > $#$value;
    push @subchecks, [
                      $value->[ $i ],
                      $content_schemata->[ $i ],
                      { data_path  => [ [$i, 'index' ] ],
                        check_path => [
                          [ 'contents', 'key' ],
                          [ $i, 'index' ]
                        ],
                      },
                     ];
  }

  if (@$value > @$content_schemata) {
    if ($self->{tail_check}) {
      push @subchecks, [
                        $value,
                        $self->{tail_check},
                        { check_path => [ ['tail', 'key' ] ] },
                       ];
    } else {
      push @subchecks,
        $self->new_fail({
          error   => [ qw(size) ],
          size    => 0 + @$value,
          value   => $value,
          message => sprintf(
            "too many entries found; found %s, need no more than %s",
            0 + @$value,
            0 + @$content_schemata,
          ),
        });
    }
  }

  $self->perform_subchecks(\@subchecks);

  return 1;
}

1;
