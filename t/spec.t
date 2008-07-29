use strict;
use warnings;
use autodie;
use File::Find::Rule;
use Test::More;

use lib 't/lib';
use Test::RxSpec;

plan 'no_plan';

# my @types = qw(num int rat txt bool scalar nil def map arr seq);
my @files = File::Find::Rule->file->in('spec/schemata');

for my $type (@files) {
  $type =~ s{^spec/schemata/}{};
  $type =~ s{\.json$}{};
  Test::RxSpec->test_spec($type);
}
