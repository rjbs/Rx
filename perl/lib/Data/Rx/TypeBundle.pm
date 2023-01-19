use v5.12.0;
use warnings;
package Data::Rx::TypeBundle;
# ABSTRACT: base class for type bundles

sub prefix_pairs {
  return if ref $_[0] and $_[0]->{no_prefix};
  $_[0]->_prefix_pairs;
}

sub without_prefix {
  bless { no_prefix => 1 } => $_[0];
}

1;
