use strict;
use warnings;
package Data::Rx::CoreType::rec;
use base 'Data::Rx::CoreType';
# ABSTRACT: the Rx //rec type

use Scalar::Util ();

sub subname   { 'rec' }

sub new_checker {
  my ($class, $arg, $rx) = @_;
  my $self = $class->SUPER::new_checker({}, $rx);

  Carp::croak("unknown arguments to new") unless
  Data::Rx::Util->_x_subset_keys_y($arg, {
    rest     => 1,
    required => 1,
    optional => 1,
  });

  my $content_schema = {};

  $self->{rest_schema} = $rx->make_schema($arg->{rest}) if $arg->{rest};

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

  $self->{content_schema} = $content_schema;
  return $self;
}

sub validate {
  my ($self, $value) = @_;

  die unless
    ! Scalar::Util::blessed($value) and ref $value eq 'HASH';

  my $c_schema = $self->{content_schema};

  my @rest_keys = grep { ! exists $c_schema->{$_} } keys %$value;
  die if @rest_keys and not $self->{rest_schema};

  for my $key (keys %$c_schema) {
    my $check = $c_schema->{$key};
    die if not $check->{optional} and not exists $value->{$key};
    die if exists $value->{$key} and ! $check->{schema}->check($value->{$key});
  }

  if (@rest_keys) {
    my %rest = map { $_ => $value->{$_} } @rest_keys;
    die unless $self->{rest_schema}->check(\%rest);
  }

  return 1;
}

1;
