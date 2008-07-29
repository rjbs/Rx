use strict;
use warnings;
package Data::Rx::CoreType::map;
use base 'Data::Rx::CoreType';

use Scalar::Util ();

sub authority { '' }
sub type      { 'map' }

sub new {
  my ($class, $arg) = @_;

  Carp::croak("unknown arguments to new") unless
  Data::Rx::Util->_x_subset_keys_y($arg, { required => 1, optional => 1 });

  my $content_check = {};

  TYPE: for my $type (qw(required optional)) {
    next TYPE unless my $entries = $arg->{$type};

    for my $entry (keys %$entries) {
      Carp::croak("$entry appears in both required and optional")
        if $content_check->{ $entry };

      $content_check->{ $entry } = {
        optional => $type eq 'optional',
        checker  => Data::Rx->new->make_checker($entries->{ $entry }),
      };
    }
  };

  return bless { content_check => $content_check } => $class;
}

sub check {
  my ($self, $value) = @_;

  return unless
    ! Scalar::Util::blessed($value) and ref $value eq 'HASH';

  my $c_check = $self->{content_check};
  return unless Data::Rx::Util->_x_subset_keys_y($value, $c_check);

  for my $key (keys %$c_check) {
    my $check = $c_check->{$key};
    return if not $check->{optional} and not exists $value->{$key};
    return if exists $value->{$key} and ! $check->{checker}->($value->{$key});
  }

  return 1;
}

1;
