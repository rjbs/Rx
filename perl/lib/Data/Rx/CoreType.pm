use v5.12.0;
use warnings;
package Data::Rx::CoreType;
# ABSTRACT: base class for core Rx types

use parent 'Data::Rx::CommonType::EasyNew';

use Carp ();

sub type_uri {
  sprintf 'tag:codesimply.com,2008:rx/core/%s', $_[0]->subname
}

1;
