
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

    my @lm = map { $model->last_modified( $_ ) } @$files;

    use Digest::MD5 qw/ md5_hex /;
    my $md5 = md5_hex( join '', ( @$files, @lm, $config->{ minify } ) );

    if ( my $file = $model->exist( "bunch/$md5" ) ) {        
        $self->c->log->info("Банч $md5 типа $type загружен." );
        return $model->url_to("bunch/$md5");

    } 
    else { 
        my $default = $config->{ default_libs }->{ $type };

        my $text;
        foreach ( ( @$default, @$files ) ) {
            eval { $text .= $model->load( $_ ); };
            $self->c->log->error( $@ ) if $@;
        }

        if ( $config->{ minify } ) {
            my $minifier = $config->{ minifiers }->{ $type };
            eval "use $minifier qw/ minify /";
            $text = minify( $text ) ;

        }#if

        $model->save( "bunch/$md5", $text );
        $self->c->log->info("Банч $md5 типа $type создан и загружен." );
        $self->$type( [ ] );

        return $model->url_to("bunch/$md5");

    }#else if

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

    $slave->c( shift ) unless defined $slave->c;

    return $slave;

}

1;
