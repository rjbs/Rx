use strict;
use warnings;
package Data::Rx::CoreType::def;
use base 'Data::Rx::CoreType';
# ABSTRACT: the Rx //def type

sub validate {
  my ($self, $value) = @_;

  return 1 if defined $value;

  $self->fail({
    error   => [ qw(fail) ],
    message => "found value is undef",
  });
}

sub subname   { 'def' }

1;
