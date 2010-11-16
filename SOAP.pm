
package Catalyst::Plugin::SOAP::Slave;
use MooseX::Singleton;

use SOAP::Lite +trace => 'all';

has params => ( is => 'rw', isa => 'Str', default => 'soap' );

has readable => ( is => 'rw', isa => 'Bool', default => '1' );

has c => ( is => 'rw', isa => 'Object' );

sub client {
    my ( $self, $service ) = @_;

    my $client = SOAP::Lite->service( 
        $self->c->config->{ 'Plugin::SOAP' }->{ $service }->{ 'wsdl' } 
    );

    $client->readable( $self->readable );

    $client->ns( 'http://schemas.xmlsoap.org/soap/envelope/', 'soap12' );

    return $client;

}#client

sub send {        
    my ( $self, $service, $method, $args ) = @_;
    
    my $client = $self->client( $service ); 

    eval { $client->$method( @$args ); };

    $self->c->log->error( $@ ) if $@;
  
}#send

sub AUTOLOAD {
    my $self = shift;

    our $AUTOLOAD;

    $AUTOLOAD =~ /\:\:([^\:]+)$/;

    if ( $self->c->config->{ 'Plugin::SOAP' }->{ $1 } ) {
        return $self->client( $1 ); 
    } 
    else {
        $self->c->error( "Unknown SOAP service $1 !" );
    }
    
}#AUTOLOAD

package Catalyst::Plugin::SOAP;

sub SOAP {
    my $slave = Catalyst::Plugin::SOAP::Slave->instance;

    $slave->c( shift ) unless defined $slave->c;

    return $slave;

}

1;
