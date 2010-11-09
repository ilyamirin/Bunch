
package Catalyst::Plugin::Bunch;
use Moose;

use JavaScript::Minifier::XS qw(minify);
use File::Util;

#has path_to => ( is => 'rw', isa => 'Str', default => 'root/static/js/' );

#has loader => ( is => 'ro', isa => 'File::Util', 
#    default => sub { File::Util->new; } );

sub load_static {
    my ( $c, $js, $css ) = @_;

    my $loader = File::Util->new;
    my $path = 'root/static/js/';

    my %static;

    foreach ( @$js ) {
        eval {
            $static{ js } .= minify( $loader->load_file( $path . $_ ) );
        };
        $c->log->error( $@ ) if $@;
    }

    $c->stash->{ static } = \%static;
    
#    $c->log->info($c->stash->{ static }->{ js });
}

1;
