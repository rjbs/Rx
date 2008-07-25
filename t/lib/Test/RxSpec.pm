use strict;
use warnings;
package Test::RxSpec;

use autodie;
use Data::Rx;
use JSON::XS;
use Test::More;

sub test_spec {
  my ($self, $which) = @_;
  my $spec_json = do { local $/; open my $fh, '<', "spec/$which.json"; <$fh> };
  my $spec = JSON::XS->new->decode($spec_json);

  my ($schema, @examples) = @$spec;

  my $rx = Data::Rx->new;

  for my $example (@examples) {
    my $ok    = $example->[0];
    my $json  = $example->[1];
    my $input = JSON::XS->new->decode("[ $json ]")->[0];

    if ($ok) {
      ok(  $rx->check($input, $schema), "'$json' is valid $schema->{type}");
    } else {
      ok(! $rx->check($input, $schema), "'$json' is invalid $schema->{type}");
    }
  }
}

1;
