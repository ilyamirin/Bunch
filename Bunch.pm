
use MooseX::Declare;

class Catalyst::Plugin::Bunch {

    has md5 => ( is => 'ro', isa => 'Digest::MD5', 
        default => sub { Digest::MD5->new } );

    sub load_js {
        my ( $c, $files ) = @_;

        my $model = $c->model( $c->config->{ Bunch }->{ model}->{ js } );

        my $default = $c->config->{ Bunch }->{ default_libs }->{ js };
        
        my $js;
        foreach ( ( @$default, @$files ) ) {
            eval {
                $js .= $model->load( $_ );
            };
            $c->log->error( $@ ) if $@;
        }

        use JavaScript::Minifier::XS qw(minify);

        use Digest::MD5 qw/ md5_hex /;
        my $md5 = md5_hex( $js );

        if ( my $file = $model->exist( "bunch/$md5.js" ) ) {
            $c->stash->{ static }->{ js } = 
                '<script>' . $file . '</script>';
            $c->log->info("Банч с именем $md5.js загружен." );
        } 
        else {
            $js = minify( $js ) if $c->config->{ Bunch }->{ minify };
            $c->stash->{ static }->{ js } = '<script>' . $js . '</script>';
            $model->save( "bunch/$md5.js", $js );
            $c->log->info("Банч с именем $md5.js создан и загружен." );
        } 

#        $c->log->info( $js );

    
    }#load_js

}#class


