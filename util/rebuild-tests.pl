#!/usr/local/bin/perl
use strict;
use warnings;

use autodie;
use File::Find::Rule;
use JSON 2 ();
use Scalar::Util;
use Try::Tiny;

my @test_sets;

# LOAD THE DATA FILES
my %data_set;

my @data_files   = File::Find::Rule->file->in('spec/data');

for my $file (@data_files) {
  (my $name = $file) =~ s{\.json\z}{};
  $name =~ s{spec/data/}{};

  die "already loaded data called $name" if exists $data_set{$name};

  my $data = slurp_json($file);
  $data = { map { $_ => $_ } @$data } if ref $data eq 'ARRAY';

  $data_set{$name} = $data;
}

# LOAD THE SCHEMA TEST FILES
my @schema_files = File::Find::Rule->file->in('spec/schemata');

SCHEMA: for my $file (@schema_files) {
  (my $name = $file) =~ s{\.json}{};
  $name =~ s{spec/data/}{};

  my $spec = slurp_json($file);

  my $set = { schema => $spec->{schema} };

  if ($spec->{invalid}) {
    $set->{invalid} = \1;
    $set->{name} = $name;
    push @test_sets, $set;
    next SCHEMA;
  }

  for my $pf (qw(pass fail)) {
    for my $source (keys %{ $spec->{$pf} }) {
      my $expect = normalize($spec->{$pf}{ $source }, $data_set{ $source });

      my $tests = $set->{tests} = [ ];

      for my $entry (keys %$expect) {
        die "bogus test input $name $source $pf"
          if $pf eq 'fail' and ! $expect->{$entry};

        push @$tests, {
          input  => $data_set{ $source }{ $entry },
          errors => $expect->{$entry} || [],
        };
      }

      push @test_sets, $set;
    }
  }
}

open my $fh, '>', 'spec.json';
print {$fh} JSON->new->pretty->canonical->encode(\@test_sets);
close $fh;

sub normalize {
  my ($spec, $test_data) = @_;
  my $ref  = ref $spec;

  my %entries
    = $ref eq 'HASH'  ? %$spec
    : $ref eq 'ARRAY' ? (map {; $_ => undef } @$spec)
    : $ref            ? die("invalid test spec: $spec")
    : $spec eq '*'    ? ('*' => [])
    : Carp::croak("invalid test spec: $spec");

  if (keys %entries == 1 and exists $entries{'*'}) {
    my $value = $entries{'*'};
    %entries = map {; $_ => $value } keys %$test_data;
  }

  for my $key (keys %entries) {
    my $eref = ref $entries{ $key };
    $entries{ $key } = [ $entries{ $key } ]
      if defined $eref and $eref eq 'HASH';
  }

  return \%entries;
}

my $JSON;
sub slurp_json {
  my ($fn) = @_;
  $JSON ||= JSON->new;

  my $json = do { local $/; open my $fh, '<', $fn; <$fh> };
  my $data = eval { $JSON->decode($json) };
  die "$@ (in $fn)" unless $data;
  return $data;
}

1;
