use strict;
use warnings;
package Test::RxSpec;

use autodie;
use Data::Rx;
use File::Find::Rule;
use JSON 2 ();
use Test::More;

my $JSON = JSON->new;
sub decode_json { $JSON->decode($_[0]) }

sub slurp_json {
  my ($fn) = shift || $_;
  $fn = "spec/$fn.json";
  my $json = do { local $/; open my $fh, '<', $fn; <$fh> };
  my $data = eval { decode_json($json) };
  die "$@ (in $fn)" unless $data;
  return $data;
}

# I really, really should go to bed before this gets any more awful.
# -- rjbs, 2008-07-28
my $DATA;
sub data {
  return $DATA if $DATA;

  $DATA = {};

  for (File::Find::Rule->file->in('spec/data')) {
    s{spec/}{};
    s{\.json}{};
    my $data = slurp_json;
    $data = { map { $_ => $_ } @$data } if ref $data eq 'ARRAY';

    s{data/}{};
    $DATA->{ $_ } = $data;
  }

  return $DATA;
}

my $fudge = {
  int => { str => "Perl has trouble with num/str distinction", },
  num => { str => "Perl has trouble with num/str distinction", },
  str => { num => "Perl has trouble with num/str distinction", },

  'num-0'           => { str => "Perl has trouble with num/str distinction", },
  'int-0'           => { str => "Perl has trouble with num/str distinction", },
  'int-range-empty' => { str => "Perl has trouble with num/str distinction", },
  'num-range' => {
    str => {
      '5.1' => 'Perl has trouble with num/str distinction',
    },
  },

  'array-3-int' => {
    arr => {
      '0-s1-1' => 'Perl has trouble with num/str distinction',
    },
  },
};

sub fudge_reason {
  my ($schema, $source, $entry) = @_;

  return unless $fudge->{$schema}
     and my $se_reason = $fudge->{$schema}{$source};

  return $se_reason if ! ref $se_reason;
  return unless my $reason = $se_reason->{$entry};
  return $reason;
}

sub test_spec {
  my ($self, $schema_fn) = @_;

  my $schema_test = slurp_json("schemata/$schema_fn");

  my $rx = Data::Rx->new;
  my $schema = eval { $rx->make_schema($schema_test->{schema}) };
  my $error   = $@;

  if ($schema_test->{invalid}) {
    ok($error && ! $schema, "BAD SCHEMA: $schema_fn");
    return;
  }

  Carp::croak("could not produce schema for valid input ($schema_fn): $error")
    unless $schema;

  my %pf = (
    pass => sub { ok($schema->check($_[0]),   "VALID  : $_[2] against $_[1]") },
    fail => sub { ok(! $schema->check($_[0]), "INVALID: $_[2] against $_[1]") },
  );

  for my $pf (keys %pf) {
    for my $source (keys %{ $schema_test->{$pf} }) {
      my $entries = $schema_test->{$pf}{ $source };
      my @entries = ref $entries    ? @$entries
                  : $entries eq '*' ? keys %{ data->{$source} }
                  : Carp::croak("invalid test specification: $entries");

      for my $entry (@entries) {
        my $json  = data->{ $source }->{ $entry };

        my $input = decode_json("[ $json ]")->[0];

        TODO: {
          my $reason = fudge_reason($schema_fn, $source, $entry);
          local $TODO = $reason if $reason;
          $pf{$pf}->($input, $schema_fn, "$source/$entry");
        }
      }
    }
  }
}

1;
