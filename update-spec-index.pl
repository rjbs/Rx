#!/usr/bin/perl
use strict;
use warnings;

use File::Find::Rule;
use JSON::XS;

my @files = File::Find::Rule->file->in('spec');
my $json = JSON::XS->new->encode(\@files);

print "$json\n";
