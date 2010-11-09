
use MooseX::Declare;

class Catalyst::Plugin::Bunch {

    #has js_minifier => ( is => 'ro', isa => '', default => sub {} );

    sub load_js {
        my ( $c, $files ) = @_;

        my $model = $c->model( $c->config->{ Bunch }->{ model}->{ js } );

        my $default = $c->config->{ Bunch }->{ default_libs }->{ js };
        
        my $js;
        foreach ( ( @$default, @$files ) ) {
            eval {
                $js .= $model->file( $_ )->slurp;
            };
            $c->log->error( $@ ) if $@;
        }

        use JavaScript::Minifier::XS qw(minify);

        $js = minify( $js ) if $c->config->{ Bunch }->{ minify };

        $c->log->info( $js );

        $c->stash->{ static }->{ js } = '<script>' . $js . '</script>';
    
    }#load_js

}#class


