
package Catalyst::Plugin::SOAP::Slave;
use MooseX::Singleton;

use SOAP::WSDL;

has c => ( is => 'rw', isa => 'Object' );

sub send {         
    my ( $self, $service, $method, $args ) = @_;

    SOAP::WSDL
        ->new( wsdl => $service )
        ->call( $method, $method => $args );
  
}#send

sub AUTOLOAD {
    my $self = shift;

    our $AUTOLOAD;

    $AUTOLOAD =~ /\:\:([^\:]+)$/;

    my $service = $self->c->config->{ 'Plugin::SOAP' }->{ $1 };

    if ( $service ) {
#        return $self->send( $service, $2 ); 
    } 
    else {
        $self->c->log->error( "Unknown SOAP service $1 !" );
    }
    
}#AUTOLOAD

package Catalyst::Plugin::SOAP;

sub SOAP {
    my $slave = Catalyst::Plugin::SOAP::Slave->instance;

    $slave->c( shift );

    return $slave;

}

1;
