use v5.12.0;
use warnings;
package Data::Rx;
# ABSTRACT: perl implementation of Rx schema system

use Data::Rx::Util;
use Data::Rx::TypeBundle::Core;

=head1 SYNOPSIS

  my $rx = Data::Rx->new;

  my $success = {
    type     => '//rec',
    required => {
      location => '//str',
      status   => { type => '//int', value => 201 },
    },
    optional => {
      comments => {
        type     => '//arr',
        contents => '//str',
      },
    },
  };

  my $schema = $rx->make_schema($success);

  my $reply = $json->decode( $agent->get($http_request) );

  die "invalid reply" unless $schema->check($reply);

=head1 COMPLEX CHECKS

Note that a "schema" can be represented either as a name or as a definition.
In the L</SYNOPSIS> above, note that we have both, '//str' and
C<{ type =E<gt> '//int', value =E<gt> 201 }>.
With the L<collection types|http://rx.codesimply.com/coretypes.html#collect>
provided by Rx, you can validate many complex structures.  See L</learn_types>
for how to teach your Rx schema object about the new types you create.

When required, see L<Data::Rx::Manual::CustomTypes> for details on creating a
custom type plugin as a Perl module.

=head1 SCHEMA METHODS

The objects returned by C<make_schema> should provide the methods detailed in
this section.

=head2 check

  my $ok = $schema->check($input);

This method just returns true if the input is valid under the given schema, and
false otherwise.  For more information, see C<assert_valid>.

=head2 assert_valid

  $schema->assert_valid($input);

This method will throw an exception if the input is not valid under the schema.
The exception will be a L<Data::Rx::FailureSet>.  This has two important
methods: C<stringify> and C<failures>.  The first provides a string form of the
failure.  C<failures> returns a list of L<Data::Rx::Failure> objects.

Failure objects have a few methods of note:

  error_string - a human-friendly description of what went wrong
  stringify    - a stringification of the error, data, and check string
  error_types  - a list of types for the error; like tags

  data_string  - a string describing where in the input the error occured
  value        - the value found at the data path

  check_string - a string describing which part of the schema found the error

=head1 SEE ALSO

L<http://rx.codesimply.com/>

=cut

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

=method new

  my $rx = Data::Rx->new(\%arg);

This returns a new Data::Rx object.

Valid arguments are:

  prefix        - optional; a hashref of prefix pairs for type shorthand
  type_plugins  - optional; an arrayref of type or type bundle plugins
  no_core_types - optional; if true, core type bundle is not loaded
  sort_keys     - optional; see the sort_keys section.

The prefix hashref should look something like this:

  {
    'pobox'  => 'tag:pobox.com,1995:rx/core/',
    'skynet' => 'tag:skynet.mil,1997-08-29:types/rx/',
  }

=cut

sub new {
  my ($class, $arg) = @_;
  $arg ||= {};
  $arg->{prefix} ||= {};

  my @plugins = @{ $arg->{type_plugins} || [] };
  unshift @plugins, $class->core_bundle unless $arg->{no_core_bundle};

  my $self = {
    prefix    => { },
    handler   => { },
    sort_keys => !!$arg->{sort_keys},
  };

  bless $self => $class;

  $self->register_type_plugin($_) for @plugins;

  $self->add_prefix($_ => $arg->{prefix}{ $_ }) for keys %{ $arg->{prefix} };

  return $self;
}

=method make_schema

  my $schema = $rx->make_schema($schema);

This returns a new schema checker method for the given Rx input. This object
will have C<check> and C<assert_valid> methods to test data with.

=cut

sub make_schema {
  my ($self, $schema) = @_;

  $schema = { type => "$schema" } unless ref $schema;

  Carp::croak("no type name given") unless my $type = $schema->{type};

  my $type_uri = $self->_expand_uri($type);
  die "unknown type uri: $type_uri" unless exists $self->{handler}{$type_uri};

  my $handler = $self->{handler}{$type_uri};

  my $schema_arg = {%$schema};
  delete $schema_arg->{type};

  my $checker;

  if (ref $handler) {
    if (keys %$schema_arg) {
      Carp::croak("composed type does not take check arguments");
    }
    $checker = $self->make_schema($handler->{'schema'});
  } else {
    $checker = $handler->new_checker($schema_arg, $self, $type);
  }

  return $checker;
}

=method register_type_plugin

  $rx->register_type_plugin($type_or_bundle);

Given a type plugin, this registers the plugin with the Data::Rx object.
Bundles are expanded recursively and all their plugins are registered.

Type plugins must have a C<type_uri> method and a C<new_checker> method.
See L<Data::Rx::Manual::CustomTypes> for details.

=cut

sub register_type_plugin {
  my ($self, $starting_plugin) = @_;

  my @plugins = ($starting_plugin);
  PLUGIN: while (my $plugin = shift @plugins) {
    if ($plugin->isa('Data::Rx::TypeBundle')) {
      my %pairs = $plugin->prefix_pairs;
      $self->add_prefix($_ => $pairs{ $_ }) for keys %pairs;

      unshift @plugins, $plugin->type_plugins;
    } else {
      my $uri = $plugin->type_uri;

      Carp::confess("a type plugin is already registered for $uri")
        if $self->{handler}{ $uri };

      $self->{handler}{ $uri } = $plugin;
    }
  }
}

=method learn_type

  $rx->learn_type($uri, $schema);

This defines a new type as a schema composed of other types.

For example:

  $rx->learn_type('tag:www.example.com:rx/person',
                  { type     => '//rec',
                    required => {
                      firstname => '//str',
                      lastname  => '//str',
                    },
                    optional => {
                      middlename => '//str',
                    },
                  },
                 );

=cut

sub learn_type {
  my ($self, $uri, $schema) = @_;

  Carp::confess("a type handler is already registered for $uri")
    if $self->{handler}{ $uri };

  die "invalid schema for '$uri': $@"
    unless eval { $self->make_schema($schema) };

  $self->{handler}{ $uri } = { schema => $schema };
}

=method add_prefix

  $rx->add_prefix($name => $prefix_string);

For example:

  $rx->add_prefix('.meta' => 'tag:codesimply.com,2008:rx/meta/');

=cut

sub add_prefix {
  my ($self, $name, $base) = @_;

  Carp::confess("the prefix $name is already registered")
    if $self->{prefix}{ $name };

  $self->{prefix}{ $name } = $base;
}

=method sort_keys

  $rx->sort_keys(1);

When sort_keys is enabled, causes Rx checkers for //rec and //map to
sort the keys before validating.  This results in failures being
produced in a consistent order.

=cut

sub sort_keys {
  my $self = shift;

  $self->{sort_keys} = !!$_[0] if @_;

  return $self->{sort_keys};
}

sub core_bundle {
  return 'Data::Rx::TypeBundle::Core';
}

sub core_type_plugins {
  my ($self) = @_;

  Carp::cluck("core_type_plugins deprecated; use Data::Rx::TypeBundle::Core");

  Data::Rx::TypeBundle::Core->type_plugins;
}

1;
