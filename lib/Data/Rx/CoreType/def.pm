package Data::Rx::CoreType::def;
use Mouse;

sub check {
  my ($self, $value) = @_;

  return defined $value;
}

sub authority { '' }
sub type      { 'def' }

__PACKAGE__->meta->make_immutable;
no Mouse;
1;
