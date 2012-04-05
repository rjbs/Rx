#!perl
use strict;
use warnings;
use 5.10.1;

use lib 'perl/lib';
use Data::Rx;
use YAML::XS;

my $rx = Data::Rx->new;

my $schema_yaml = <<'END_YAML';
---
type: //all
of:
  - //def
  - type: //seq
    contents:
    - //int 
    - //nil
    - type: //rec
      required:
        foo: //int
        bar: //int
      optional:
        baz:
          type: //arr
          contents:
            type: //all
            of  : [ //def, //num, //int ]
END_YAML

my ($schema_def) = YAML::XS::Load($schema_yaml);

my $schema = $rx->make_schema($schema_def);

my $input = [
  1,
  undef,
  {
    foo => 1,
    bar => 2.2,
    baz => [ 3, 4, 5, 6.2, 7 ],
  },
];

eval { $schema->assert_valid($input); };
my $fail = $@;
say $fail;

