
package Catalyst::Plugin::Bunch::File::Handler;
use Moose;

use File::Util;

has fu => ( is => 'ro', isa => 'File::Util', 
    default => sub { File::Util->new } );

has path_to => ( is => 'rw', isa => 'Str', default => 'root/' );

has base_url => ( is => 'rw', isa => 'Str', default => '/' );

has extention => ( is => 'rw', isa => 'Str' );

sub full_path {
    my ( $self, $f ) = @_;

    join '', $self->path_to, $f, '.', $self->extention;

}

sub url_to {
    my ( $self, $f ) = @_;

    join '', $self->base_url, $f, '.', $self->extention;

}

sub load {
    my ( $self, $f ) = @_;

    $self->fu->load_file( $self->full_path( $f ) );

}#load

sub save {
    my ( $self, $f, $content ) = @_;

    $self->fu->write_file( 
        'file' => $self->full_path( $f ), 
        'content' => $content, 
    );

}#save

sub exist {
    my ( $self, $f ) = @_;

    $self->fu->existent( $self->full_path( $f ) );

}#exist

sub last_modified {
    my ( $self, $f ) = @_;

    $self->fu->last_modified( $self->full_path( $f ) );

}#last_modified


package Catalyst::Plugin::Bunch::Slave;
use MooseX::Singleton;

has c => ( is => 'rw', isa => 'Object' );

has js => ( is => 'rw', isa => 'ArrayRef', default => sub { [ ] } );

has css => ( is => 'rw', isa => 'ArrayRef', default => sub { [ ] } );

sub load {
    my ( $self, $type ) = @_;
    
    my $files = $self->$type;

    my $config = $self->c->config->{ Bunch };

    my $file_handler = Catalyst::Plugin::Bunch::File::Handler->new(
        path_to   => "root/static/$type/",
        base_url  => "/$type/",
        extention => $type,
    );

    my $lang = $self->c->session->{ locale }->{ lang };
    map { $_ = "$lang/$_" if $file_handler->exist( "$lang/$_" ) } @$files; 

    my @lm = map { $file_handler->last_modified( $_ ) } @$files;

    use Digest::MD5 qw/ md5_hex /;
    my $md5 = md5_hex( join '', ( @$files, @lm, $config->{ minify } ) );

    if ( $file_handler->exist( "bunch/$md5" ) ) {        
        $self->c->log->info( "Банч $md5 типа $type загружен." );

    } 
    else { 
        my $default = $config->{ default_libs }->{ $type };

        my $text;
        $text .= $file_handler->load( $_ ) foreach ( @$default, @$files );

        if ( $config->{ minify } ) {
            my $minifier = $config->{ minifiers }->{ $type };
            eval "use $minifier qw/ minify /";
            $text = minify( $text ) ;

        }#if

        $file_handler->save( "bunch/$md5", $text );

        $self->c->log->info( "Банч $md5 типа $type создан и загружен." );

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
