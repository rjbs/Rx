use strict;
use warnings;
package Data::Rx;

use Module::Pluggable::Object;

sub new {
  my ($class) = @_;

  my $mpo = Module::Pluggable::Object->new(
    search_path => 'Data::Rx::CoreType',
  );

  my $self = {};

  my @plugins = $mpo->plugins;
  for my $plugin (@plugins) {
    eval "require $plugin; 1" or die;
    $self->{handlers}{ $plugin->authority }{ $plugin->type } = $plugin;
  }

  bless $self => $class;
  return $self;
}

sub check {
  my ($self, $value, $schema) = @_;

  my ($authority, $type) = $schema->{type} =~ m{\A / (\w*) / (\w+) \z}x;

  die "unknown schema: $schema->{type}"
    unless my $handler = $self->{handlers}{ $authority }{ $type };

  $handler->check($value);
}

1;
