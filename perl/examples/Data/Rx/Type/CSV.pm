use strict;
use warnings;
package Data::Rx::Type::CSV;
use parent 'Data::Rx::CommonType::EasyNew';

use String::Trim;

use Carp ();

sub type_uri {
  'tag:codesimply.com,EXAMPLE:rx/csv',
}

sub guts_from_arg {
  my ($class, $arg, $rx) = @_;

  my $meta = $rx->make_schema({
    type     => '//rec',
    required => {
      # not yet implemented, see http://rx.codesimply.com/moretypes.html
      # contents => '/.meta/schema',
      contents => '//any',
    },
    optional => {
      trim => {

        # we don't just accept //bool as this only includes 'boolean' objects,
        # let's also allow undef/0/1, as this is more Perlish!
        type => '//any',
        of   => [ '//nil', '//bool', '//int' ]
      },
    },
  });

  $meta->assert_valid($arg);

  return {
    trim        => $arg->{trim},
    str_schema  => $rx->make_schema('//str'),
    item_schema => $rx->make_schema($arg->{contents}),
  };
}

sub assert_valid {
  my ($self, $value) = @_;

  $self->{str_schema}->assert_valid($value);

  my @values = split ',' => $value;

  my $item_schema = $self->{item_schema};
  my $trim        = $self->{trim};

  for my $subvalue (@values) {
    trim($subvalue) if $trim;

    $item_schema->assert_valid($subvalue);
  }

  return 1;
}

1;
