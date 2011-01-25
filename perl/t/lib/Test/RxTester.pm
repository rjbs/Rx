use strict;
use warnings;
package Test::RxTester;

use autodie;
use Data::Rx;
use File::Find::Rule;
use JSON ();
use Scalar::Util;
use Test::Deep::NoTest;
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
  my ($schema, $schema_desc, $input, $input_desc, $want)
    = @$arg{ qw(schema schema_desc input input_desc want) };

  try {
    $schema->validate($input);
    Test::More::pass("$schema_desc should ACCEPT $input_desc");
  } catch {
    Test::More::fail("$schema_desc should ACCEPT $input_desc");
    # should diag the failure paths here
  }
}

sub assert_fail {
  my ($self, $arg) = @_;
  my ($schema, $schema_desc, $schema_spec, $input, $input_desc, $want)
    = @$arg{ qw(schema schema_desc schema_spec input input_desc want) };

  try {
    $schema->validate($input);
    Test::More::fail("$schema_desc should REJECT $input_desc");
  } catch {
    my $fail = $_;
    my $desc = "$schema_desc should REJECT $input_desc";
    my $ok   = 1;
    my @diag;

    $want = $want ? $want->[0] : {};

    if (try { $fail->isa('Data::Rx::Failure') }) {
      if ($want->{data}) {
        eq_deeply([$fail->data_path],$want->{data})
          or do {
            $ok = 0;
            my $want = @{ $want->{data} } ? "[ @{ $want->{data} } ]" : '(empty)';
            my $have = $fail->data_path ? "[ @{[$fail->data_path]} ]" : '(empty)';
            push @diag, "want path to data: $want",
                        "have path to data: $have";
          };
        my $ref_to_value = check_path($input, [$fail->data_path]);
        if ($ref_to_value) {
          eq_deeply($$ref_to_value, shallow($fail->value))
            or do {
              $ok = 0;
              push @diag, "value at path to data does not match failure value";
            };
        } else {
          $ok = 0;
          push @diag, "invalid path to data: " . $fail->data_string;
        }
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

        # path check doesn't work for composed types...  -- rjk, 2010-12-17
        $schema_desc =~ /composed/
          or check_path($schema_spec, [$fail->check_path])
            or do {
              $ok = 0;
              push @diag, "invalid path to check: " . $fail->check_string;
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
    } else {
      $ok = 0;
      my $desc = Scalar::Util::blessed($fail) ? Scalar::Util::blessed($fail)
               : ref($fail)     ? "unblessed " . ref($fail)
               :                  "non-ref: $fail";

      push @diag, 'want $@: Data::Rx::Failure',
                  'have $@: ' . $desc;
    }

    Test::More::ok($ok, $desc);
    Test::More::diag "    $_" for @diag;
  }
}

sub check_path {
  my ($data, $path) = @_;

  my @path = @$path;

  while (@path) {
    ref $data or return;

    my $key = shift @path;

    if (ref $data eq 'ARRAY') {
      $key =~ /^\d+\z/ or return;
      $key <= $#$data
        or return;
      $data = $data->[$key];
    } elsif (ref $data eq 'HASH') {
      exists $data->{$key}
        or return;
      $data = $data->{$key};
    } else {
      return;
    }
  }

  return \$data;
}

sub run_tests {
  my ($self) = @_;

  my $spec_data = $self->{spec};
  SPEC: for my $spec_name (sort keys %$spec_data) {
    my $spec = $spec_data->{ $spec_name };

    my $rx     = Data::Rx->new;

    if ($spec->{'composed-type'}) {
      my $rc =
        eval { $rx->learn_type($spec->{'composed-type'}{'uri'},
                               $spec->{'composed-type'}{'schema'});
               1 };
      my $error = $@;

      if ($spec->{'composed-type'}{'invalid'}) {
        Test::More::ok($error && !$rc, "BAD COMPOSED TYPE: $spec_name");
        next SPEC;
      }

      $rx->add_prefix(@{$spec->{'composed-type'}{'prefix'}})
        if $spec->{'composed-type'}{'prefix'};
    }

    my $schema = eval { $rx->make_schema($spec->{schema}) };
    my $error  = $@;

    if ($spec->{invalid}) {
      Test::More::ok($error && ! $schema, "$spec_name should be INVALID");
      next SPEC;
    }

    Carp::croak("couldn't produce schema for valid input ($spec_name): $error")
      unless $schema;

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
