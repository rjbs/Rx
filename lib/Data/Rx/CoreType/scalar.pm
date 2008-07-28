package Data::Rx::CoreType::scalar;
use Mouse;

sub check {
  my ($self, $value) = @_;

  return unless defined $value;
  return if ref $value and ! eval { $value->isa('JSON::XS::Boolean'); };
  return 1;
}

sub authority { '' }
sub type      { 'scalar' }

__PACKAGE__->meta->make_immutable;
no Mouse;
1;
