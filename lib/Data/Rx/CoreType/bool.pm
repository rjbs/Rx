package Data::Rx::CoreType::bool;
use Mouse;

sub check {
  my ($self, $value) = @_;

  return(
    defined($value)
    and ref($value)
    and eval { $value->isa('JSON::XS::Boolean') }
  );
}

sub authority { '' }
sub type      { 'bool' }

__PACKAGE__->meta->make_immutable;
no Mouse;
1;
