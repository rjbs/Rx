#!/usr/bin/env perl
use strict;
use warnings;

use autodie;
use File::Find::Rule;
use JSON 2 ();
use Params::Util qw(_HASHLIKE);
use Scalar::Util;
use Try::Tiny;

my %test_set;

# LOAD THE DATA FILES
my %data_set;

my @data_files   = File::Find::Rule->file->name('*.json')->in('spec/data');

for my $file (@data_files) {
  (my $name = $file) =~ s{\.json\z}{};
  $name =~ s{spec/data/}{};

  die "already loaded data called $name" if exists $data_set{$name};

  my $data = slurp_json($file);
  $data = { map { $_ => $_ } @$data } if ref $data eq 'ARRAY';

  $data_set{$name} = $data;
}

# LOAD THE SCHEMA TEST FILES
my @schema_files = File::Find::Rule->file->name('*.json')->in('spec/schemata');

my $count = 0;

SCHEMA: for my $file (@schema_files) {
  (my $name = $file) =~ s{\.json}{};
  $name =~ s{spec/schemata/}{};

  my $spec = slurp_json($file);

  my $set = { schema => $spec->{schema} };

  if ($spec->{invalid}) {
    $set->{invalid} = \1;
    $test_set{ $name } = $set;
    $count += 1;
    next SCHEMA;
  }

  if ($spec->{'composedtype'}) {
    $set->{'composedtype'} = $spec->{'composedtype'};

    if ($spec->{'composedtype'}{'invalid'}) {
      $test_set{ $name } = $set;
      $count += 1;
      next SCHEMA;
    }
  }

  for my $pf (qw(pass fail)) {
    for my $source (keys %{ $spec->{$pf} }) {
      my $expect = normalize($spec->{$pf}{ $source }, $data_set{ $source });

      my $test = $set->{test} ||= { };

      for my $entry (keys %$expect) {
        die "bogus test input $name $source $pf"
          if $pf eq 'fail' and ! $expect->{$entry}{'errors'};

        $test->{"$source/$entry"} = {
          input  => $data_set{ $source }{ $entry },
          %{ $expect->{$entry} },
        };

        $count += 1;

        $count += 1
          if $pf eq 'fail' and $expect->{$entry}{'errors_struct'};
      }

      $test_set{ $name } = $set;
    }
  }
}

open my $fh, '>', 'spec/spec.json';

print {$fh} JSON->new->pretty->canonical->encode({
  count => $count,
  tests => \%test_set
});

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
    if (! $entries{ $key }) {
      $entries{ $key } = { errors => [] };
    } elsif ( defined $eref and $eref eq 'ARRAY' ) {
      $entries{ $key } = { errors => $entries{ $key } };
    } elsif ( defined $eref and $eref eq 'HASH' and
              ! exists $entries{ $key }{'errors'} ) {
      $entries{ $key } = { errors => [ $entries{ $key } ] };
    }
  }

  return \%entries;
}

my $JSON;
sub slurp_json {
  my ($fn) = @_;
  $JSON ||= JSON->new->relaxed;

  my $json = do { local $/; open my $fh, '<', $fn; <$fh> };
  my $data = eval { $JSON->decode($json) };
  die "$@ (in $fn)" unless $data;
  return $data;
}

1;
