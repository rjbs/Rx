package Data::Rx::CoreType::int;
use Mouse;
extends 'Data::Rx::CoreType::num';

sub _dec_re { '' }

sub authority { '' }
sub type      { 'int' }

__PACKAGE__->meta->make_immutable;
no Mouse;
1;
