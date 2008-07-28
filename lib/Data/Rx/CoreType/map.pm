package Data::Rx::CoreType::map;
use Mouse;

has 'contents' => (
  is  => 'ro',
  isa => 'HashRef',
  required => 1,
);

use Scalar::Util ();

sub authority { '' }
sub type      { 'map' }

sub check {
  my ($self, $value) = @_;

  return(
    ! Scalar::Util::blessed($value) and ref $value eq 'HASH'
  );
}

__PACKAGE__->meta->make_immutable;
no Mouse;
1;
