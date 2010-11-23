
package Catalyst::Plugin::SOAP;

use SOAP::WSDL;

sub SOAP {
    my ( $c, $service, $method, $args ) = @_;

    my $wsdl = $c->config->{ 'Plugin::SOAP' }->{ $service }->{ wsdl };

    die "Unknown SOAP service $service !" unless $wsdl;

    my $client = SOAP::WSDL->new( wsdl => $wsdl );

    $client->call( $method, $method => $args );
 
}

1;
