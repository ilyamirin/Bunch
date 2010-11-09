
package Catalyst::Plugin::Bunch;
use Moose;

use JavaScript::Minifier::XS qw(minify);
use File::Util;

sub load_static {
    my ( $c, $js, $css, %static ) = @_;

    my $loader = File::Util->new;

    my $path = $c->config->{ Bunch }->{ path_to } || 'root/static/js/';
             $c->log->info( 
                $c->model('File::JS')->file( 'user/index.js' ) . ': ' .
                $c->model('File::JS')->file( 'user/index.js' )->slurp
            );
    
    foreach ( @$js ) {
        eval {
            $static{ js } .= minify( $c->model('File::JS')->file( $_ ) );
            $c->log->info( 
                $c->model('File::JS')->file( $_ ) . ': ' .
                $c->model('File::JS')->file( $_ )->slurp
            );
            #$loader->load_file( $path . $_ ) );
        };
        $c->log->error( $@ ) if $@;
    }

    $static{ js } = '<script>' . $static{ js } . '</script>';

    $c->stash->{ static } = \%static;
    
#    $c->log->info($c->stash->{ static }->{ js });
}

1;
