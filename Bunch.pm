
package Catalyst::Plugin::Bunch::Slave;
use MooseX::Singleton;

use Digest::MD5 qw/ md5_hex /;

has md5 => ( is => 'ro', isa => 'Digest::MD5', 
    default => sub { Digest::MD5->new } );

has c => ( is => 'rw', isa => 'Object' );

has store => ( is => 'rw', isa => 'HashRef', default => sub { { } } );

has static => ( is => 'rw', isa => 'HashRef', default => sub { { } } );

sub _load {
    my ( $self, $type, $files ) = @_;

    my $config = $self->c->config->{ Bunch };

    my $model = $self->c->model( $config->{ model }->{ $type } );
       
    my $default = $config->{ default_libs }->{ $type };
         
    my $text;
    foreach ( ( @$default, @$files ) ) {
        eval { $text .= $model->load( $_ ); };
        $self->c->log->error( $@ ) if $@;
    }

    my $md5 = md5_hex( $text . $config->{ minify } );

    if ( my $file = $model->exist( "bunch/$md5" ) ) {
        $self->static->{ $type } = $model->url_to("bunch/$md5");
        $self->c->log->info("Банч $md5 типа $type загружен." );
    } 
    else {
        if ( $config->{ minify } ) {
            my $minifier = $config->{ minifiers }->{ $type };
            eval "use $minifier qw/ minify /";
            $text = minify( $text ) ;

        }#if

        $model->save( "bunch/$md5", $text );
        $self->static->{ $type } = $model->url_to("bunch/$md5");
        $self->c->log->info("Банч $md5 типа $type создан и загружен." );

    } #else if

    return $self->static->{ $text };

}#_load

sub load_static {        
    my $self = shift;

    use List::MoreUtils qw/ uniq /;

    while ( my ( $k, $v ) = each %{ $self->store } ) {
        @$v = uniq @$v;
        $self->_load( $k, $v );
    }

}#load_static

sub AUTOLOAD {
    my ( $self, $file ) = @_;  

    our $AUTOLOAD;

    $AUTOLOAD =~ /^.+_(.+)$/;

    push @{ $self->store->{ $1 } }, $file;

}#AUTOLOAD

package Catalyst::Plugin::Bunch;

sub bunch {    

    my $slave = Catalyst::Plugin::Bunch::Slave->instance;

    $slave->c( shift ) unless defined $slave->c;

    return $slave;

}

1;
