
package Catalyst::Plugin::Bunch::Slave;
use MooseX::Singleton;

has c => ( is => 'rw', isa => 'Object' );

has js => ( is => 'rw', isa => 'ArrayRef', default => sub { [ ] } );

has css => ( is => 'rw', isa => 'ArrayRef', default => sub { [ ] } );

sub load {
    my ( $self, $type ) = @_;

    my $config = $self->c->config->{ Bunch };

    my @files = (
        @{ $config->{ default_libs }->{ $type } },
        @{ $self->$type }
    );

    use Catalyst::Plugin::Bunch::File::Handler;
    my $file_handler = Catalyst::Plugin::Bunch::File::Handler->new(
        path_to   => "root/static/$type/",
        base_url  => "/$type/",
        extention => $type,
    );

    my $lang = $self->c->session->{ locale }->{ lang };
    map { $_ = "$lang/$_" if $file_handler->exist( "$lang/$_" ) } @files;

    my @lm = map { $file_handler->last_modified( $_ ) } @files;

    use Digest::MD5 qw/ md5_hex /;
    my $md5 = md5_hex( join '', ( @files, @lm, $config->{ minify } ) );

    if ( $file_handler->exist( "bunch/$md5" ) ) {
        $self->c->log->debug( "Bunch: Файл $md5 типа $type загружен." ) if $config->{ debug };

    }
    else {
        my $text;
        for ( @files ) {
            $text .= $file_handler->load( $_ ) ;
            $self->c->log->debug( "Bunch: Файл $_ добавлен." ) if $config->{ debug };
        }

        if ( $config->{ minify } ) {
            my $minifier = $config->{ minifiers }->{ $type };
            eval "use $minifier qw/ minify /";
            $text = minify( $text ) ;

        }#if

        $file_handler->save( "bunch/$md5", $text );

        $self->c->log->debug( "Bunch: Файл $md5 типа $type создан и загружен." ) if $config->{ debug };

    }#else if

    $self->$type( [ ] );

    return $file_handler->url_to( "bunch/$md5" );

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
