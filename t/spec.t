use strict;
use warnings;
use autodie;
use Test::More;

use lib 't/lib';
use Test::RxSpec;

plan 'no_plan';

# my @types = qw(num int rat txt bool scalar nil def map arr seq);
my @types = qw(bool def nil int array-3-int seq-isi-2bools);
my %skip  = map { $_ => 1 } qw();

for my $type (@types) {
  SKIP: {
    skip "$type is FAIL in Perl", 1 if $skip{$type};
    Test::RxSpec->test_spec($type);
  }
}
