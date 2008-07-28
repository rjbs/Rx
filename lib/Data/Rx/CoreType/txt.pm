package Data::Rx::CoreType::txt;
use Mouse;

sub check {
  my ($self, $value) = @_;

  return unless defined $value and ! ref $value;
  return 1;
}

sub authority { '' }
sub type      { 'txt' }

__PACKAGE__->meta->make_immutable;
no Mouse;
1;
