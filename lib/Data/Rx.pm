use strict;
use warnings;
package Data::Rx;

use Data::Rx::Util;
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

sub make_checker {
  my ($self, $schema, $arg) = @_;
  $arg ||= {};

  my $type = $schema->{type};
  my ($authority, $type_name) = $type =~ m{\A / (\w*) / (\w+) \z}x;

  die "unknown schema: $type"
    unless my $handler = $self->{handlers}{ $authority }{ $type_name };

  my $arg = {%$schema};
  delete $arg->{type};
  my $checker = $handler->new($arg);

  return sub {
    $checker->check($_[0]);
  }
}

1;
