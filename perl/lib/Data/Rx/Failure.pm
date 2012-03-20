package Data::Rx::Failure;
use strict;
use warnings;
# we pretend to be a false value
use overload bool => sub { 0 };
use Try::Tiny;

sub new {
    my ($class,$checker,$args) = @_;

    $args||={};

    if (!defined $args->{type}) {
        if ($checker->can('subname')) {
            $args->{type}=$checker->subname;
        }
        else {
            $args->{type}=ref($checker);
        }
    }

    if (!defined $args->{message}) {
        my $str .= 'type:'.$args->{type};
        for my $key (sort keys %$args) {
            next if $key eq 'type';
            next if $key eq 'sub_failures';
            $str .= " $key:".(defined $args->{$key} ? $args->{$key} : '<undef> ');
        }
        $args->{message} = $str;
    }

    bless $args,$class;
}

sub message {
    my ($self) = @_;

    my $str = $self->{message};

    if ($self->{sub_failures}) {
        my @subs = map {
            eval { $_->message } || (defined $_ ? "$_" : '<undef>' )
        } @{$self->{sub_failures}};
        $str .= ' ('.join(', ',@subs).')';
    }

    return $str;
}

1;
