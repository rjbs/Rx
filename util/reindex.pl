#!/usr/local/bin/perl
use strict;
use warnings;

use File::Find::Rule;
use JSON 2;

my @files = File::Find::Rule->file->in('spec');
my $json = JSON->new->encode(\@files);

print "$json\n";
