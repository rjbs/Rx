use strict;
use warnings;
package Data::Rx::Failures;
# ABSTRACT: multiple structured failure reports from an Rx checker


use overload '""' => \&stringify;

sub new {
  my ($class, $arg) = @_;

  my $failures;

  my $guts = {
    failures => [ map $_->isa('Data::Rx::Failures')
                        ? @{ $_->{failures} }
                        : $_,
                      @{ $arg->{failures} || [] },
                ]
  };

  bless $guts => $class;
}

sub failures { $_[0]->{failures} }

sub contextualize {
  my ($self, $struct) = @_;

  foreach my $failure (@{ $self->{failures} }) {
    $failure->contextualize($struct);
  }

  return $self;
}

sub stringify {
  my ($self) = @_;

  if (@{$self->{failures}}) {
    return join '', map "$_", @{$self->{failures}};
  } else {
    return "No failures\n";
  }
}

sub build_struct {
  my ($self) = @_;

  return unless @{$self->{failures}};

  my $data;

  foreach my $failure (@{$self->{failures}}) {

    my @path = $failure->data_path;
    my @type = $failure->data_path_type;

    @path == @type or die "Length mismatch";


    # go to the appropriate location in the struct, vivifying as necessary

    my $p = \$data;

    for (my $i = 0; $i < @path; ++$i) {
      if ($type[$i] eq 'k') {
        if (defined $$p && ref $$p ne 'HASH') {
          die "Path mismatch";
        }
        $$p ||= {};
        $p = \$$p->{$path[$i]};
      } elsif ($type[$i] eq 'i') {
        if (defined $$p && ref $$p ne 'ARRAY') {
          die "Path mismatch";
        }
        $$p ||= [];
        $p = \$$p->[$path[$i]];
      } else {
        die "Invalid path type";
      }
    }


    # insert the errors into the struct at the current location

    my $error = ($failure->error_types)[0];

    if ($error eq 'missing' || $error eq 'unexpected') {

      if (defined $$p && ref $$p ne 'HASH') {
        die "Path mismatch";
      }

      my @keys = $failure->keys;

      $$p ||= {};
      @{$$p}{@keys} = ($error) x @keys;

    } elsif ($error eq 'size') {

      if (defined $$p && ref $$p ne 'ARRAY') {
        die "Path mismatch";
      }

      my $size = $failure->size;

      $$p ||= [];
      $$p->[$size] = $error;

    } else {

      if (ref $$p) {
        die "Path mismatch";
      }

      $$p .= ',' if defined $$p;
      $$p .= $error;

    }
  }

  return $data;
}

1;
