
package Catalyst::Plugin::Bunch::Slave;
use MooseX::Singleton;

has c => ( is => 'rw', isa => 'Object' );

has js => ( is => 'rw', isa => 'ArrayRef', default => sub { [ ] } );

has css => ( is => 'rw', isa => 'ArrayRef', default => sub { [ ] } );

sub load {
    my ( $self, $type ) = @_;
    
    my $files = $self->$type;
    
    my $config = $self->c->config->{ Bunch };

    my $model = $self->c->model( $config->{ model }->{ $type } );

    my $lang = $self->c->session->{ locale }->{ lang };
    map { $_ = "$lang/$_" if $model->exist( "$lang/$_" ) } @$files; 

    $self->c->log->info( $lang );
    $self->c->log->info( $_ ) foreach @{ $self->$type };

    my @lm = map { $model->last_modified( $_ ) } @$files;

    use Digest::MD5 qw/ md5_hex /;
    my $md5 = md5_hex( join '', ( @$files, @lm, $config->{ minify } ) );

    if ( $model->exist( "bunch/$md5" ) ) {        
        $self->c->log->info( "Банч $md5 типа $type загружен." );

    } 
    else { 
        my $default = $config->{ default_libs }->{ $type };

        my $text;
        $text .= $model->load( $_ ) foreach ( @$default, @$files );

        if ( $config->{ minify } ) {
            my $minifier = $config->{ minifiers }->{ $type };
            eval "use $minifier qw/ minify /";
            $text = minify( $text ) ;

        }#if

        $model->save( "bunch/$md5", $text );

        $self->c->log->info( "Банч $md5 типа $type создан и загружен." );

    }#else if

    $self->$type( [ ] );

    return $model->url_to( "bunch/$md5" );

}#load

sub add {
    my ( $self, $type, $file ) = @_;  

    push @{ $self->$type }, $file;

    return;

}#add

sub AUTOLOAD {
    my $self = shift;  

    our $AUTOLOAD;

    $AUTOLOAD =~ /(.+)_(.+)$/;
    
    $self->$1( $2, shift );

}#AUTOLOAD

package Catalyst::Plugin::Bunch;

sub bunch {    
    my $slave = Catalyst::Plugin::Bunch::Slave->instance;

    $slave->c( shift );           

    return $slave;

}#bunch

1;
