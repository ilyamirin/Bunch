
use MooseX::Declare;

class Catalyst::Plugin::Bunch {

    has md5 => ( is => 'ro', isa => 'Digest::MD5', 
        default => sub { Digest::MD5->new } );

    has c => ( is => 'rw', isa => 'Object' );

    method _load ( $type, $files ) {

        my $config = $self->c->config->{ Bunch };

        my $model = $self->c->model( $config->{ model}->{ $type } );
       
        my $default = $config->{ default_libs }->{ $type };
        
        my $text;
        foreach ( ( @$default, @$files ) ) {
            eval { $text .= $model->load( $_ ); };
            $self->c->log->error( $@ ) if $@;
        }

        use Digest::MD5 qw/ md5_hex /;
        my $md5 = md5_hex( $text . $config->{ minify } );

        if ( my $file = $model->exist( "bunch/$md5" ) ) {
            $self->c->stash->{ static }->{ $type } = 
                $model->url_to("bunch/$md5");
            $self->c->log->info("Банч $md5 типа $type загружен." );
        } 
        else {
            if ( $config->{ minify } ) {
                my $minifier = 
                    $config->{ minifiers }->{ $type };
                eval "use $minifier qw/ minify /";
                $text = minify( $text ) ;
            }
            $model->save( "bunch/$md5", $text );
            $self->c->stash->{ static }->{ $type } = 
                $model->url_to("bunch/$md5");
            $self->c->log->info("Банч $md5 типа $type создан и загружен." );
        } 

        return $self->c->stash->{ static }->{ $text };

    }#_load

    sub bunch {
        return Catalyst::Plugin::Bunch->new( c => shift );
    }

    method load_static {
        
        while ( my ( $k, $v ) = each %{ $self->c->stash->{ static } } ) {
            $self->_load( $k, $v );
        }

    }#load_static

    sub add_css {
        my ( $c, $file ) = @_;

        $c->log->info( $file );

        push @{ $c->stash->{ static }->{ css } }, $file;

        $c->log->info( $_ ) foreach @{ $c->stash->{ static }->{ css } };

    }#add_static

}#class


