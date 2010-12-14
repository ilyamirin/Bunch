
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

__PACKAGE__->meta->make_immutable;

1;
