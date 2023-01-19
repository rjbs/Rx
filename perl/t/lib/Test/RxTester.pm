use v5.12.0;
use warnings;
package Test::RxTester;

use autodie;
use Data::Rx;
use File::Find::Rule;
use JSON ();
use Scalar::Util;
use Test::Deep::NoTest qw/ :DEFAULT cmp_details deep_diag /;
use Test::More ();
use Try::Tiny;

sub _decode_json {
  my ($self, $json_str) = @_;
  $self->{__json} ||= JSON->new;
  $self->{__json}->decode($json_str);
}

sub _slurp_json {
  my ($self, $fn) = @_;

  my $json = do { local $/; open my $fh, '<', $fn; <$fh> };
  my $data = eval { JSON->new->decode($json) };
  die "$@ (in $fn)" unless $data;
  return $data;
}

sub new {
  my ($class, $file) = @_;

  my $self = bless {} => $class;
  my $spec = $self->_slurp_json( $file );

  $self->{spec} = $spec->{tests};
  $self->{plan} = $spec->{count};

  return $self;
}

sub plan {
  $_[0]->{plan};
}

my $fudge = {
  int => { str => "Perl has trouble with num/str distinction", },
  num => { str => "Perl has trouble with num/str distinction", },
  str => { num => "Perl has trouble with num/str distinction", },

  'str-empty'  => { num => 'Perl has trouble with num/str distinction' },
  'str-x'      => { num => 'Perl has trouble with num/str distinction' },
  'str-length' => { num => 'Perl has trouble with num/str distinction' },

  'num-0'           => { str => 'Perl has trouble with num/str distinction', },
  'int-0'           => { str => 'Perl has trouble with num/str distinction', },
  'int-range'       => { str => 'Perl has trouble with num/str distinction', },
  'int-range-empty' => { str => 'Perl has trouble with num/str distinction', },
  'num-range'       => { str => 'Perl has trouble with num/str distinction', },

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

sub assert_pass {
  my ($self, $arg) = @_;
  my ($schema, $schema_desc, $input, $input_desc)
    = @$arg{ qw(schema schema_desc input input_desc) };

  my $desc = "$schema_desc should ACCEPT $input_desc";

  try {
    $schema->assert_valid($input);
    Test::More::pass("$desc");
  } catch {
    my $fails = $_;
    Test::More::fail("$desc");

    (my $diag = "$fails") =~ s/^/    /mg;
    Test::More::diag($diag);
  }
}

sub assert_fail {
  my ($self, $arg) = @_;
  my ($schema, $schema_desc, $schema_spec, $input, $input_desc, $want)
    = @$arg{ qw(schema schema_desc schema_spec input input_desc want) };

  my $desc = "$schema_desc should REJECT $input_desc";

  try {
    $schema->assert_valid($input);
    Test::More::fail($desc);
  } catch {
    my $fails = $_;
    my $ok   = 1;
    my @diag;

    FAILS: {
      if (try { $fails->isa('Data::Rx::FailureSet') }) {
        my $fail = $fails->failures;
        $want ||= [];

        if (@$want > 1) {
          if (@$want != @$fail) {
            $ok = 0;
            push @diag, 'want ' . @$want . ' failures',
                        'have ' . @$fail . ' failures';
            last FAILS;
          }
        } else {
          @$fail = $fail->[0];
        }

        for (my $i = 0; $i <= $#$want; ++$i) {

          my ($tmp_ok, @tmp_diag) =
            $self->compare_fail({ %$arg, want => $want->[$i],
                                         fail => $fail->[$i] });

          $tmp_ok
            or do {
              $ok = 0;
              push @diag, "want/fail index $i:",
                          map "  $_", @tmp_diag;
            };

        }

      } else {
        $ok = 0;
        my $desc = Scalar::Util::blessed($fails)
                     ? Scalar::Util::blessed($fails)
                     : ref($fails)
                       ? "unblessed " . ref($fails)
                       : "non-ref: $fails";

        push @diag, 'want $@: Data::Rx::FailureSet',
                    'have $@: ' . $desc;
      }
    }

    Test::More::ok($ok, $desc);
    Test::More::diag "    $_" for @diag;
  }
}

sub compare_fail {
  my ($self, $arg) = @_;
  my ($schema, $schema_desc, $schema_spec, $input, $input_desc, $want, $fail)
    = @$arg{ qw(schema schema_desc schema_spec input input_desc want fail) };

  my $ok = 1;
  my @diag;

  if ($want->{data}) {
    eq_deeply([$fail->data_path],$want->{data})
      or do {
        $ok = 0;
        my $want = @{ $want->{data} } ? "[ @{ $want->{data} } ]" : '(empty)';
        my $have = $fail->data_path ? "[ @{[$fail->data_path]} ]" : '(empty)';
        push @diag, "want path to data: $want",
                    "have path to data: $have";
      };
  }

  if ($want->{check}) {
    eq_deeply([$fail->check_path],$want->{check})
      or do {
        $ok = 0;
        my $want = @{ $want->{check} } ? "[ @{ $want->{check} } ]" : '(empty)';
        my $have = $fail->check_path ? "[ @{[$fail->check_path]} ]" : '(empty)';
        push @diag, "want path to check: $want",
                    "have path to check: $have";
      };
  }

  if ($want->{error}) {
    eq_deeply([sort $fail->error_types],$want->{error})
      or do {
        $ok = 0;
        my $want = @{ $want->{error} } ? "[ @{ $want->{error} } ]" : '(empty)';
        my $have = $fail->error_types ? "[ @{[$fail->error_types]} ]" : '(empty)';
        push @diag, "want error types: $want",
                    "have error types: $have";
      };
  }

  if (!$ok) {
    unshift @diag, "$fail";
  }

  return ($ok, @diag);
}

sub run_tests {
  my ($self, @spec_names) = @_;

  my $spec_data = $self->{spec};

  if (!@spec_names) {
    @spec_names = sort keys %$spec_data;
  }

  SPEC: for my $spec_name (@spec_names) {
    my $spec = $spec_data->{ $spec_name }
      or die "invalid spec name $spec_name";

    Test::More::diag "testing $spec_name";

    my $rx = Data::Rx->new({ sort_keys => 1 });

    if ($spec->{'composedtype'}) {
      my $rc =
        eval { $rx->learn_type($spec->{'composedtype'}{'uri'},
                               $spec->{'composedtype'}{'schema'});
               1 };
      my $error = $@;

      if ($spec->{'composedtype'}{'invalid'}) {
        Test::More::ok($error && !$rc, "BAD COMPOSED TYPE: $spec_name");
        next SPEC;
      }

      $rx->add_prefix(@{$spec->{'composedtype'}{'prefix'}})
        if $spec->{'composedtype'}{'prefix'};
    }

    my $schema = eval { $rx->make_schema($spec->{schema}) };
    my $error  = $@;

    if ($spec->{invalid}) {
      Test::More::ok($error && ! $schema, "$spec_name should be INVALID");
      next SPEC;
    }

    Carp::croak("couldn't produce schema for valid input ($spec_name): $error")
      unless $schema;

    Carp::croak("rx attribute not set in schema ($spec_name)")
      unless $schema->rx;

    for my $test_name (sort keys %{ $spec->{test} }) {
      my $test_spec = $spec->{test}{$test_name};

      my $input  = $self->_decode_json("[ $test_spec->{input} ]")->[0];

      my $method = @{ $test_spec->{errors} } ? 'assert_fail' : 'assert_pass';

      TODO: {
        my ($source, $entry) = split m{/}, $test_name, 2;
        my $reason = fudge_reason($spec_name, $source, $entry);

        local our $TODO = $reason if $reason;
        $self->$method({
          schema      => $schema,
          schema_desc => $spec_name,
          schema_spec => $spec->{schema},
          input       => $input,
          input_desc  => $test_name,
          want        => $test_spec->{errors},
        });
      }
    }
  }
}

1;
