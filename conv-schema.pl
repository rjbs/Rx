#!/usr/bin/perl
use strict;
use warnings;
use 5.010;
use autodie;
use JSON::XS;
use YAML::XS;
use Data::Dumper;
use Data::Visitor::Callback;

my @schemata = Load(scalar `cat schema.yaml`);
my $visitor  = Data::Visitor::Callback->new(value => sub {
  $_ += 0 if defined $_ and /^\d+/;
});

$visitor->visit(\@schemata);

my @json = map { JSON::XS->new->pretty(1)->encode($_) } @schemata;
my @perl = map { Dumper($_) } @schemata;

sub wf {
  my ($lines, $fn) = @_;
  die "file $fn exists" if -e $fn;
  open my $fh, '>', $fn;
  say $fh $_ for @$lines;
}

wf(\@json => 'schema.json');
wf(\@perl => 'schema.pl');
