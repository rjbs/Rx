use strict;
use warnings;
package Data::Rx::CoreType::one;
use base 'Data::Rx::CoreType';
# ABSTRACT: the Rx //one type

sub validate {
  my ($self, $value) = @_;

  if (! defined $value) {
    $self->fail({
      error   => [ qw(type) ],
      message => "found value is undef",
    });
  }

  return 1 unless ref $value and ! (
    eval { $value->isa('JSON::XS::Boolean') }
    or
    eval { $value->isa('JSON::PP::Boolean') }
    or
    eval { $value->isa('boolean') }
  );

  $self->fail({
    error   => [ qw(type) ],
    message => "found value is a reference/container type",
  });
}

sub subname   { 'one' }

1;
