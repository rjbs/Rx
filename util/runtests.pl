#!/usr/bin/perl
use strict;
use warnings;
use TAP::Harness;

my $harness = TAP::Harness->new({
  exec => sub {
    my ($self, $filename) = @_;
    return [ $^X, -I => 'perl/lib', -I => 'perl/t/lib', $filename ] if $filename =~ /\.t$/;
    return [ 'java', -jar => 'js.jar', $filename ] if $filename =~ /\.js$/;
    return [ 'ruby', -I => 'ruby', $filename ] if $filename =~ /\.rb$/;
    return [ 'python', $filename ] if $filename =~ /\.py$/;
  },
});

# You may only choose one of 'exec', 'stream', 'tap' or 'source' at - line 12

$harness->runtests(qw(
  perl/t/spec.t
  perl/t/util-range.t
  ruby/rx-test.rb
  python/rx-test.py
  js/rx/test/runner.js
));
