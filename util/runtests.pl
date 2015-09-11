#!/usr/bin/env perl
use 5.010;
use strict;
use warnings;
use TAP::Harness;

my %interp;

$interp{perl} = $ENV{PERL} || $^X;
$interp{$_}   = $ENV{ uc $_ } || $_ for qw(java ruby python php);

my %ext = (
  t   => [ 'perl', -I => 'perl/lib', -I => 'perl/t/lib' ],
  js  => [ 'java', -jar => 'js.jar' ], # yeah yeah yeah, bad naming
  rb  => [ 'ruby', -I => 'ruby' ],
  py  => [ 'python', ],
  php => [ 'php', ],
);

my $harness = TAP::Harness->new({
  exec => sub {
    my ($self, $filename) = @_;

    for my $ext (keys %ext) {
      next unless $filename =~ /\.\Q$ext\E$/;
      my @entry = (@{ $ext{$ext} }, $filename);
      $entry[0] = $interp{ $entry[0] };
      return \@entry;
    }
  },
});

# You may only choose one of 'exec', 'stream', 'tap' or 'source' at - line 12
my @testfiles = qw(
  js/rx/test/runner.js
  perl/t/spec.t
  perl/t/util-range.t
  php/rx-test.php
  php/util-test.php
  python/rx-test.py
  ruby/rx-test.rb
);

if (@ARGV) {
  my %want_lang = map {; $_ => 1 } @ARGV;
  @testfiles = grep { my ($lang) = m{^(\w+)/}; $want_lang{$lang} } @testfiles;
}

$harness->runtests(@testfiles);
