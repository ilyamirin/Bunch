package Catalyst::Plugin::MD5;
use Digest::MD5 qw/ md5_hex /;
use Encode;

sub uuid {
    my ( $c, $source ) = @_;
    md5_hex( encode_utf8( join'' => @$source ) ) =~ m/(.{8})(.{4})(.{4})(.{4})(.{12})/;
    join '-' => $1, $2, $3, $4, $5;
}

1;
