use v5.12.0;
use warnings;
package Data::Rx::CoreType::rec;
# ABSTRACT: the Rx //rec type

use parent 'Data::Rx::CoreType';

use Scalar::Util ();

sub subname   { 'rec' }

sub guts_from_arg {
  my ($class, $arg, $rx, $type) = @_;

  Carp::croak("unknown arguments to new") unless
    Data::Rx::Util->_x_subset_keys_y($arg, {
      rest     => 1,
      required => 1,
      optional => 1,
    });

  my $guts = {};

  my $content_schema = {};

  $guts->{rest_schema} = $rx->make_schema($arg->{rest}) if $arg->{rest};

  TYPE: for my $type (qw(required optional)) {
    next TYPE unless my $entries = $arg->{$type};

    for my $entry (keys %$entries) {
      Carp::croak("$entry appears in both required and optional")
        if $content_schema->{ $entry };

      $content_schema->{ $entry } = {
        optional => $type eq 'optional',
        schema   => $rx->make_schema($entries->{ $entry }),
      };
    }
  };

  $guts->{content_schema} = $content_schema;
  return $guts;
}

sub assert_valid {
  my ($self, $value) = @_;

  unless (! Scalar::Util::blessed($value) and ref $value eq 'HASH') {
    $self->fail({
      error   => [ qw(type) ],
      message => "value is not a hashref",
      value   => $value,
    });
  }

  my $c_schema = $self->{content_schema};

  my @subchecks;

  my @rest_keys = grep { ! exists $c_schema->{$_} } keys %$value;
  if (@rest_keys and not $self->{rest_schema}) {
    @rest_keys = sort @rest_keys;
    push @subchecks,
      $self->new_fail({
        error    => [ qw(unexpected) ],
        keys     => [@rest_keys],
        message  => "found unexpected entries: @rest_keys",
        value    => $value,
      });
  }

  for my $key ($self->rx->sort_keys ? sort keys %$c_schema : keys %$c_schema) {
    my $check = $c_schema->{$key};

    if (not $check->{optional} and not exists $value->{ $key }) {
      push @subchecks,
        $self->new_fail({
          error    => [ qw(missing) ],
          keys     => [$key],
          message  => "no value given for required entry $key",
          value    => $value,
        });
      next;
    }

    if (exists $value->{$key}) {
      push @subchecks, [
        $value->{$key},
        $check->{schema},
        { data_path  => [ [$key, 'key' ] ],
          check_path => [
            [ $check->{optional} ? 'optional' : 'required', 'key' ],
            [ $key, 'key' ],
          ],
        },
       ];
    }
  }

  if (@rest_keys && $self->{rest_schema}) {
    my %rest = map { $_ => $value->{$_} } @rest_keys;

    push @subchecks, [
      \%rest,
      $self->{rest_schema},
      { check_path => [ ['rest', 'key' ] ],
      },
    ];
  }

  $self->perform_subchecks(\@subchecks);

  return 1;
}

1;
