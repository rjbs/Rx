use strict;
use warnings;
package Test::RxSpec;

use autodie;
use Data::Rx;
use File::Find::Rule;
use JSON::XS;
use Test::More;

my $JSON = JSON::XS->new;

sub slurp_json {
  my ($fn) = shift || $_;
  $fn = "spec/$fn.json";
  my $json = do { local $/; open my $fh, '<', $fn; <$fh> };
  my $data = eval { $JSON->decode( $json ) };
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
  my ($self, $schema) = @_;

  my $schema_test = slurp_json("schemata/$schema");

  my $rx = Data::Rx->new;
  my $checker = eval { $rx->make_checker($schema_test->{schema}) };
  my $error   = $@;

  if ($schema_test->{invalid}) {
    ok($error && ! $checker, "BAD SCHEMA: $schema");
    return;
  }

  Carp::croak("could not produce validator for valid input ($schema): $error")
    unless $checker;

  my %pf = (
    pass => sub { ok($checker->($_[0]),   "VALID  : $_[2] against $_[1]") },
    fail => sub { ok(! $checker->($_[0]), "INVALID: $_[2] against $_[1]") },
  );

  for my $pf (keys %pf) {
    for my $source (keys %{ $schema_test->{$pf} }) {
      my $entries = $schema_test->{$pf}{ $source };
      my @entries = ref $entries    ? @$entries
                  : $entries eq '*' ? keys %{ data->{$source} }
                  : Carp::croak("invalid test specification: $entries");

      for my $entry (@entries) {
        my $json  = data->{ $source }->{ $entry };

        my $input = $JSON->decode("[ $json ]")->[0];

        TODO: {
          my $reason = fudge_reason($schema, $source, $entry);
          local $TODO = $reason if $reason;
          $pf{$pf}->($input, $schema, "$source/$entry");
        }
      }
    }
  }
}

1;
