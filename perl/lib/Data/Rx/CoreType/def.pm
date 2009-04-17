use strict;
use warnings;
package Data::Rx::CoreType::def;
use base 'Data::Rx::CoreType';
# ABSTRACT: the Rx //def type

sub validate {
  my ($self, $value) = @_;

  return 1 if defined $value;

  $self->fail({
    error   => [ qw(type) ],
    message => "found value is undef",
    value   => $value, # silly, but let's be consistent -- rjbs, 2009-04-17
  });
}

sub subname   { 'def' }

1;
