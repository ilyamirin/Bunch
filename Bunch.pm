
use MooseX::Declare;

class Catalyst::Plugin::Bunch {

    use JavaScript::Minifier::XS qw(minify);

    sub load_static {
        my ( $c, $js, $css, %static ) = @_;
        
        foreach ( @$js ) {
            eval {
                $static{ js } .= $c->model('File::JS')->file( $_ )->slurp;
            };
            $c->log->error( $@ ) if $@;
        }

        $static{ js } = '<script>' . minify( $static{ js } ) . '</script>';

        $c->stash->{ static } = \%static;
    
    }#load_static

}#class


