use strict;
use warnings;
package Test::RxTester;

use autodie;
use Data::Rx;
use File::Find::Rule;
use JSON ();
use Scalar::Util;
use Test::Deep::NoTest;
use Test::More;
use Try::Tiny;

sub new {
  my ($class, $arg) = @_;
  $arg ||= {};
  
  my $guts = {
    schema_files => $arg->{schema_files},
    data_files   => $arg->{data_files},
  };

  my $self = bless $guts => $class;

  $self->_load_data_files;
  $self->_load_schema_files;

  return $self;
}

sub _load_data_files {
  my ($self) = @_;

  for my $fn (@{ $self->{data_files} }) {
    my ($name) = File::Basename::fileparse($fn);
    $name =~ s{\.json}{};

    die "already loaded data called $name" if exists $self->{data}{$name};

    my $data = $self->slurp_json($fn);
    $data = { map { $_ => $_ } @$data } if ref $data eq 'ARRAY';

    $self->{data}{$name} = $data;
  }
}

sub _load_schema_files {
  my ($self) = @_;

  for my $fn (@{ $self->{schema_files} }) {
    my ($name) = File::Basename::fileparse($fn);
    $name =~ s{\.json}{};

    die "already loaded schema spec tests for $name"
      if exists $self->{spec}{$name};

    my $data = $self->slurp_json($fn);
    $data = { map { $_ => $_ } @$data } if ref $data eq 'ARRAY';

    $self->{spec}{$name} = {
      invalid => $data->{invalid},
      schema  => $data->{schema},
      expect  => { },
    };

    for my $pf (qw(pass fail)) {
      for my $source (keys %{ $data->{$pf} }) {
        my $spec = $data->{$pf}{ $source };
        my $ref  = ref $spec;

        my %entries
          = $ref eq 'HASH'  ? %$spec
          : $ref eq 'ARRAY' ? (map {; $_ => undef } @$spec)
          : $ref            ? die("invalid test spec: $spec")
          : $spec eq '*'    ? ('*' => undef)
          : Carp::croak("invalid test spec: $spec");

        if (keys %entries == 1 and exists $entries{'*'}) {
          my $value = $entries{'*'};
          %entries = map {; $_ => $value } keys %{ $self->test_data($source) };
        }

        $self->{spec}{$name}{expect}{$source}{$pf} = \%entries;
      }
    }
  }
}

sub test_data {
  my ($self, $name) = @_;

  die "no such test data: $name" unless exists $self->{data}{$name};
  return $self->{data}{$name};
}

sub _decode_json {
  my ($self, $json_str) = @_;
  $self->{__json} ||= JSON->new;
  $self->{__json}->decode($json_str);
}

sub slurp_json {
  my ($self, $fn) = @_;

  my $json = do { local $/; open my $fh, '<', $fn; <$fh> };
  my $data = eval { $self->_decode_json($json) };
  die "$@ (in $fn)" unless $data;
  return $data;
}

my $fudge = {
  int => { str => "Perl has trouble with num/str distinction", },
  num => { str => "Perl has trouble with num/str distinction", },
  str => { num => "Perl has trouble with num/str distinction", },

  'str-empty' => { num => 'Perl has trouble with num/str distinction' },
  'str-x'     => { num => 'Perl has trouble with num/str distinction' },

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
    pass("VALID  : $input_desc against $schema_desc");
  } catch {
    fail("VALID  : $input_desc against $schema_desc");
    # should diag the failure paths here
  }
}

sub assert_fail {
  my ($self, $arg) = @_;
  my ($schema, $schema_desc, $input, $input_desc, $want)
    = @$arg{ qw(schema schema_desc input input_desc want) };

  try {
    $schema->validate($input);
    fail("INVALID: $input_desc against $schema_desc");
  } catch {
    my $fail = $_;
    my $desc = "INVALID: $input_desc against $schema_desc";
    my $ok   = 1;
    my @diag;

    if (try { $fail->isa('Data::Rx::Failure') }) {
      $want ||= {};
      if ($want->{value} && ! eq_deeply([$fail->path_to_value],$want->{value})){
        $ok = 0;
        my $want = @{ $want->{value} } ? "[ @{ $want->{value} } ]" : '(empty)';
        my $have = $fail->path_to_value ? "[ @{[$fail->path_to_value]} ]" : '(empty)';
        push @diag, "want path to value: $want",
                    "have path to value: $have";
      }

      if ($want->{check} && ! eq_deeply([$fail->path_to_check],$want->{check})){
        $ok = 0;
        my $want = @{ $want->{check} } ? "[ @{ $want->{check} } ]" : '(empty)';
        my $have = $fail->path_to_check ? "[ @{[$fail->path_to_check]} ]" : '(empty)';
        push @diag, "want path to check: $want",
                    "have path to check: $have";
      }

      if ($want->{error} && ! eq_deeply([sort $fail->failure_types],$want->{error})) {
        $ok = 0;
        my $want = @{ $want->{error} } ? "[ @{ $want->{error} } ]" : '(empty)';
        my $have = $fail->failure_types ? "[ @{[$fail->failure_types]} ]" : '(empty)';
        push @diag, "want error types: $want",
                    "have error types: $have";
      }
    } else {
      $ok = 0;
      my $desc = Scalar::Util::blessed($fail) ? Scalar::Util::blessed($fail)
               : ref($fail)     ? "unblessed " . ref($fail)
               :                  "non-ref: $fail";

      push @diag, 'want $@: Data::Rx::Failure',
                  'have $@: ' . $desc;
    }

    ok($ok, $desc);
    diag "    $_" for @diag;
  }
}

sub run_tests {
  my ($self) = @_;

  my $spec_data = $self->{spec};
  SPEC: for my $spec_name (sort keys %$spec_data) {
    my $spec = $spec_data->{ $spec_name };

    my $rx     = Data::Rx->new;
    my $schema = eval { $rx->make_schema($spec->{schema}) };
    my $error  = $@;

    if ($spec->{invalid}) {
      ok($error && ! $schema, "BAD SCHEMA: $spec_name");
      next SPEC;
    }

    Carp::croak("couldn't produce schema for valid input ($spec_name): $error")
      unless $schema;

    for my $pf (qw(pass fail)) {
      my $method = "assert_$pf";

      my @sources = keys %{ $spec->{expect} };

      for my $source (@sources) {
        my $entries = $spec->{expect}{ $source }{ $pf };
        for my $entry (keys %$entries) {
          my $json  = $self->test_data($source)->{ $entry };

          my $input = $self->_decode_json("[ $json ]")->[0];

          TODO: {
            my $reason = fudge_reason($spec_name, $source, $entry);
            local $TODO = $reason if $reason;
            $self->$method({
              schema      => $schema,
              schema_desc => $spec_name,
              input       => $input,
              input_desc  => "$source/$entry",
              want        => $entries->{ $entry },
            });
          }
        }
      }
    }
  }
}

1;
