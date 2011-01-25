use strict;
use warnings;
use autodie;
use File::Find::Rule;
use Test::More;

use lib 't/lib';
use Test::RxTester;

Test::Builder->new->failure_output(\*STDOUT);

my $rx_tester = Test::RxTester->new('spec/spec.json');

my @spec_names = @ARGV;

if (@spec_names) {
  plan 'no_plan';
} else {
  plan tests => $rx_tester->plan;
}

$rx_tester->run_tests(@spec_names);
