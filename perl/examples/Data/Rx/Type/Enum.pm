use strict;
use warnings;

package Data::Rx::Type::Enum;

use parent 'Data::Rx::CommonType::EasyNew';

use Carp ();

sub type_uri {
  'tag:codesimply.com,EXAMPLE:rx/enum',
}

sub guts_from_arg {
  my ($class, $arg, $rx) = @_;

  my $meta = $rx->make_schema({
    type     => '//rec',
    required => {
      contents => {
        type     => '//rec',
        required => {
          type   => '//str',  # e.g. //int or //str.  Really we only
                              # want schemas that have a 'value' option
          values => {
            type     => '//arr',
            contents => '//def',

            # should be of type, as above, but we can't test this,
            # so we accept any defined value for now, and then test
            # the values below
          },
        },
      },
    },
  });

  $meta->assert_valid($arg);

  my $type   = $arg->{contents}{type};
  my @values = @{ $arg->{contents}{values} };

  # subsequent test that the provided values are acceptable
  $rx->make_schema({ type => '//arr', contents => $type })
     ->assert_valid(\@values);

  my $schema = $rx->make_schema({
    type => '//any',
    of   => [ map { { type => $type, value => $_ } } @values, ]
  });

  return { schema => $schema, };
}

sub assert_valid {
  my ($self, $value) = @_;

  $self->{schema}->assert_valid( $value );
}

1;
