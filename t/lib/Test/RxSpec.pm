use strict;
use warnings;
package Test::RxSpec;

use autodie;
use Data::Rx;
use File::Find::Rule;
use JSON::XS;
use Test::More;

my $JSON = JSON::XS->new;

sub slurp {
  my $fn = shift || $_;
  my $json = do { local $/; open my $fh, '<', "spec/$fn.json"; <$fh> };
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
    my $data_json = slurp;
    my $data = $JSON->decode($data_json);
    $data = { map { $_ => $_ } @$data } if ref $data eq 'ARRAY';

    s{data/}{};
    $DATA->{ $_ } = $data;
  }

  return $DATA;
}

sub test_spec {
  my ($self, $schema) = @_;

  my $schema_json = slurp("schemata/$schema");
  my $schema_test = $JSON->decode($schema_json);

  my $rx = Data::Rx->new;
  my $checker = $rx->make_checker($schema_test->{schema});

  my %pf = (
    pass => sub { ok($checker->($_[0]),   "VALID  : $_[2] against $_[1]") },
    fail => sub { ok(! $checker->($_[0]), "INVALID: $_[2] against $_[1]") },
  );

  for my $pf (keys %pf) {
    for my $source (keys %{ $schema_test->{$pf} }) {
      for my $entry (@{ $schema_test->{$pf}{ $source } }) {
        my $json  = data->{ $source }->{ $entry };
        my $input = $JSON->decode("[ $json ]")->[0];

        $pf{$pf}->($input, $schema, "$source/$entry");
        # ok(! $checker->($input, $schema), "'$json' is invalid $schema_desc");
      }
    }
  }
}

1;
