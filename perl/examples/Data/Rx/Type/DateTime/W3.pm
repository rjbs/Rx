use strict;
use warnings;

package Data::Rx::Type::DateTime::W3;

use parent 'Data::Rx::CommonType::EasyNew';
use DateTime::Format::W3CDTF;

use Carp ();

sub type_uri {
  'tag:codesimply.com,EXAMPLE:rx/datetime/w3',
}

sub guts_from_arg {
  my ($class, $arg, $rx) = @_;
  $arg ||= {};

  if (my @unexpected = keys %$arg) {
    Carp::croak sprintf "Unknown arguments %s in constructing %s",
      (join ',' => @unexpected), $class->type_uri;
  }

  return { dt => DateTime::Format::W3CDTF->new, };
}

sub assert_valid {
  my ($self, $value) = @_;

  return 1 if $value && eval { $self->{dt}->parse_datetime($value); };

  $self->fail({
    error   => [qw(type)],
    message => "found value is not a w3 datetime",
    value   => $value,
  });
}

1;
