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

1;
