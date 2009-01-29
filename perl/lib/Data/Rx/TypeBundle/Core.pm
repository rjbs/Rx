use strict;
use warnings;
package Data::Rx::TypeBundle::Core;
use base 'Data::Rx::TypeBundle';
# ABSTRACT: the bundle of core Rx types

use Module::Pluggable::Object;

sub _prefix_pairs {
  return (
    ''      => 'tag:codesimply.com,2008:rx/core/',
    '.meta' => 'tag:codesimply.com,2008:rx/meta/',
  );
}

my @plugins;
sub type_plugins {
  return @plugins if @plugins;

  my $mpo = Module::Pluggable::Object->new(
    search_path => 'Data::Rx::CoreType',
    require     => 1,
  );

  return @plugins = $mpo->plugins;
}

1;
