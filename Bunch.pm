
use MooseX::Declare;

class Catalyst::Plugin::Bunch {

    has md5 => ( is => 'ro', isa => 'Digest::MD5', 
        default => sub { Digest::MD5->new } );

    method _load ( $c, $type, $files ) {

        my $config = $c->config->{ Bunch };

        my $model = $c->model( $config->{ model}->{ $type } );
       
        my $default = $config->{ default_libs }->{ $type };
        
        my $text;
        foreach ( ( @$default, @$files ) ) {
            eval { $text .= $model->load( $_ ); };
            $c->log->error( $@ ) if $@;
        }

        use Digest::MD5 qw/ md5_hex /;
        my $md5 = md5_hex( $text . $config->{ minify } );

        if ( my $file = $model->exist( "bunch/$md5" ) ) {
            $c->stash->{ static }->{ $type } = $model->url_to("bunch/$md5");
            $c->log->info("Банч $md5 типа $type загружен." );
        } 
        else {
            if ( $config->{ minify } ) {
                my $minifier = 
                    $config->{ minifiers }->{ $type };
                eval "use $minifier qw/ minify /";
                $text = minify( $text ) ;
            }
            $model->save( "bunch/$md5", $text );
            $c->stash->{ static }->{ $type } = $model->url_to("bunch/$md5");
            $c->log->info("Банч $md5 типа $type создан и загружен." );
        } 

        return $c->stash->{ static }->{ $text };

    }#_load

    method load_static ( $c ) {
        
        while ( my ( $k, $v ) = each %{ $c->stash->{ static } } ) {
            $self->_load( $c, $k, $v );
        }

   }#load_static

}#class


