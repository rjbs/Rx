package Data::Rx::CoreType::nil;
use Mouse;

sub check {
  my ($self, $value) = @_;

  return ! defined $value;
}

sub authority { '' }
sub type      { 'nil' }

__PACKAGE__->meta->make_immutable;
no Mouse;
1;
