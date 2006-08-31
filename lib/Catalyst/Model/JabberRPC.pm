package Catalyst::Model::JabberRPC;
use base qw/Catalyst::Model/;
use strict;
use warnings;

use Carp;
use NEXT;
use Jabber::RPC::Client;

our $VERSION = '0.01';
our $AUTOLOAD;


sub new {
    my ($class, $c, $config) = @_;

    my $self = $class->NEXT::new($c, $config);

    return $self;
}


sub _client {
    my $self = shift;
    my %config = %{ $self->config };

    for my $key (qw/server identauth endpoint/) {
        croak "Must provide $key" unless exists $config{$key};
    }

    my $client = Jabber::RPC::Client->new(%config);
    croak "Can't create Jabber::RPC::Client object"
        unless UNIVERSAL::isa($client, 'Jabber::RPC::Client');

    return $client;
}


sub AUTOLOAD {
    my ($self, @args) = @_;
    
    return if $AUTOLOAD =~ /::DESTROY$/;

    (my $op = $AUTOLOAD) =~ s/^.*:://;

    # Create a new client connection
    my $client = $self->_client;

    if (my $msg = $client->$op(@args)) {
        if (ref $msg eq 'HASH' && exists $msg->{faultString}) {
            croak $msg->{faultString};
        }
        return $msg;
    }
    else {
        # If the execution failed by some reason we simply die
        croak $client->lastfault;
    }
}


1;

__END__

=head1 NAME

Catalyst::Model::JabberRPC - JabberRPC model class for Catalyst

=head1 SYNOPSIS

 # Model
 __PACKAGE__->config(
    server    => 'myserver.org',
    identauth => 'user:password',
    endpoint  => 'jrpc.myserver.org/rpc-server',
 );

 # Controller
 sub default : Private {
    my ($self, $c) = @_;

    my $result;
    
    eval {
        $result = $c->model('RemoteService')->call('examples.getStateName', 5);
        $c->stash->{value} = $result;
    }
    if ($@) {
        ...
    }
    ...
 };


=head1 DESCRIPTION

This model class uses L<Jabber::RPC::Client> to invoke remote procedure calls
using XML-RPC calls over Jabber.

=head1 CONFIGURATION

You can pass the same configuration fields as when you call
L<Jabber::RPC::Client>.

=head1 METHODS

=head2 General

Take a look at L<Jabber::RPC::Client> to see the method you can call.

=head2 new

Called from Catalyst.

=head1 NOTES

This module will croak (die) if the execution of the remote proceduce failed,
and also if the return message is a hashref which contain a key named
B<faultString>.

=head1 SEE ALSO

=over 1

=item * L<Jabber::RPC::Client>

=item * L<Catalyst::Model>

=back

=head1 AUTHOR

Florian Merges, E<lt>fmerges@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
