#!perl
use strict;
use warnings;

use lib 'perl/lib';
use Data::Rx;

my $rx = Data::Rx->new;

my $schema_def = {
  type      => '//seq',
  contents  => [
    '//int', 
    '//nil',
    {
      type     => '//rec',
      required => {
        foo => '//int',
        bar => '//int',
      },
      optional => {
        baz => {
          type     => '//arr',
          contents => '//int',
        },
      },
    },
  ],
};

my $schema = $rx->make_schema($schema_def);

my $input = [
  1,
  undef,
  {
    foo => 1,
    bar => 2,
    baz => [ 3, 4, 5, 6.2, 7 ],
  },
];

eval { $schema->validate($input); };
my $fail = $@;

use YAML::XS;
print Dump($fail->struct);

__END__
---
- error:
  - type
  message: found value is not an integer
  type: tag:codesimply.com,2008:rx/core/int
- entry: 3
  type: tag:codesimply.com,2008:rx/core/arr
- entry: baz
  type: tag:codesimply.com,2008:rx/core/rec
- entry: 2
  type: tag:codesimply.com,2008:rx/core/seq

