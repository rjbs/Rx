use strict;
use warnings;
package Data::Rx;
# ABSTRACT: perl implementation of Rx schema system

use Data::Rx::Util;
use Module::Pluggable::Object;

sub __built_in_prefixes {
  return (
    ''      => 'tag:codesimply.com,2008:rx/core/',
    '.meta' => 'tag:codesimply.com,2008:rx/meta/',
  );
}

sub _expand_uri {
  my ($self, $str) = @_;
  return $str if $str =~ /\A\w+:/;

  if ($str =~ m{\A/(.*?)/(.+)\z}) {
    my ($prefix, $rest) = ($1, $2);
  
    my $lookup = $self->{prefix};
    Carp::croak "unknown prefix '$prefix' in type name '$str'"
      unless exists $lookup->{$prefix};

    return "$lookup->{$prefix}$rest";
  }

  Carp::croak "couldn't understand Rx type name '$str'";
}

sub new {
  my ($class, $arg) = @_;
  $arg ||= {};

  my $mpo = Module::Pluggable::Object->new(
    search_path => 'Data::Rx::CoreType',
  );

  my $self = {
    prefix  => { $class->__built_in_prefixes },
    handler => {},
  };

  bless $self => $class;

  my @plugins = $mpo->plugins;
  for my $plugin (@plugins) {
    eval "require $plugin; 1" or die;
    $self->{handler}{ $plugin->type_uri } = $plugin;
  }

  return $self;
}

sub make_schema {
  my ($self, $schema, $arg) = @_;
  $arg ||= {};

  $schema = { type => "$schema" } unless ref $schema;

  Carp::croak("no type name given") unless my $type = $schema->{type};

  my $type_uri = $self->_expand_uri($type);
  die "unknown type uri: $type_uri" unless exists $self->{handler}{$type_uri};

  my $handler = $self->{handler}{$type_uri};

  my $schema_arg = {%$schema};
  delete $schema_arg->{type};
  my $checker = $handler->new($schema_arg, $self);

  return $checker;
}

1;
