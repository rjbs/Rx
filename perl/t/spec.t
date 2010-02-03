use strict;
use warnings;
use autodie;
use File::Find::Rule;
use Test::More;

use lib 't/lib';
use Test::RxTester;

Test::Builder->new->failure_output(\*STDOUT);

plan 'no_plan';

my @schema_files = File::Find::Rule->file->in('spec/schemata');
my @data_files   = File::Find::Rule->file->in('spec/data');

my $rx_tester = Test::RxTester->new({
  schema_files => \@schema_files,
  data_files   => \@data_files,
});

$rx_tester->run_tests;
