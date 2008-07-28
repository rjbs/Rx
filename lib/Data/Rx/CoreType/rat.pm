package Data::Rx::CoreType::rat;
use Mouse;
extends 'Data::Rx::CoreType::num';

sub authority { '' }
sub type      { 'rat' }

__PACKAGE__->meta->make_immutable;
no Mouse;
1;
