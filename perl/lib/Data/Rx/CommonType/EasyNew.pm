use v5.12.0;
use warnings;
package Data::Rx::CommonType::EasyNew;
# ABSTRACT: base class for core Rx types, with some defaults

use parent 'Data::Rx::CommonType';

use Carp ();

sub guts_from_arg {
  my ($class, $arg, $rx, $type) = @_;

  Carp::croak "$class does not take check arguments" if %$arg;

  return {};
}

sub new_checker {
  my ($class, $arg, $rx, $type) = @_;

  my $guts = $class->guts_from_arg($arg, $rx, $type);

  # Carp::confess "underscore-led entry in guts!" if grep /\A_/, keys %$guts;
  $guts->{_type} = $type;
  $guts->{_rx}   = $rx;

  bless $guts => $class;
}

sub type { $_[0]->{_type} }

sub rx { $_[0]->{_rx} }

=pod

=head1 NOTE

For examples on how to subclass this, see L<Data::Rx::Manual::CustomTypes>.

=cut

1;
