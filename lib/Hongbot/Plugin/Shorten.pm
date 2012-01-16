package Hongbot::Plugin::Shorten;
use URI;
use Mojo::DOM;
use File::Temp;
use AnyEvent::HTTP;
use Encode qw(decode encode_utf8);
use WWW::Shorten 'TinyURL';
use HTTP::Status qw(:constants :is status_message);

use Moose;
use namespace::autoclean;
extends 'Hongbot::Plugin';
with 'MooseX::Role::Pluggable::Plugin';

override 'usage' => sub { '<https?://ANY_URI/>' };
override 'regex' => sub { qr{((!)?(?:https?:)(?://[^\s/?#]*)[^\s?#]*(?:\?[^\s#]*)?(?:#.*)?)} };

sub hear {
    my ($self, $cl, $channel, $nickname, $msg) = @_;

    my $regex = $self->regex;
    while ($msg =~ m/$regex/g) {
        my $uri = URI->new($1);
        my $shorten;
        next unless $uri->scheme && $uri->scheme =~ m/^http/i;
        next unless $uri->authority;

        if ($uri->host =~ m/twitter/) {
            my $plist = $self->parent->plugin_list;
            return if ($plist && grep { /twitter/i } @$plist);
        }

        if (length $uri->as_string > 50 && $uri->authority !~ /tinyurl|bit\.ly/) {
            $shorten = URI->new(makeashorterlink($uri))
        } else {
            $shorten = $uri;
        }

        my $file;
        my ($is_text, $content_type, $charset);
        my $guard; $guard = http_get $uri,
            on_header => sub {
                my ($headers) = @_;

                if ($headers->{Status} != HTTP_OK) {
                    $self->to_channel(
                        $cl,
                        $channel,
                        sprintf(
                            "[%s] - %s",
                            status_message($headers->{Status}),
                            $shorten
                        )
                    );
                    return;
                }

                $content_type = $headers->{'content-type'};
                if ($content_type =~ m/image/i) {
                    $self->to_channel(
                        $cl,
                        $channel,
                        sprintf(
                            "[%s] - %s",
                            $content_type,
                            $shorten
                        )
                    );
                    return;
                }

                $is_text = $content_type =~ m/text/i;
                return unless $is_text;

                ($charset) = $content_type =~ m{charset\s*=\s*(\w+)}i;
                return 1;
            },
            on_body => sub {
                $file ||= File::Temp->new(UNLINK => 1);
                print $file $_[0];
                return 1;
            },
            sub {
                undef $guard;
                return unless $file;
                seek($file, 0, 0);
                my $unknown = do { local $/; <$file> };
                ($charset) = $unknown =~ m{charset=['"]?([^'"]+)['"]}i unless $charset;
                $charset //= 'utf8';
                $charset = 'euckr' if $charset =~ m/^ks/i; # ks_c_5601-1987
                my $data = decode($charset, $unknown);
                my $dom = Mojo::DOM->new($data);
                $dom->charset($charset);
                my $title = $dom->at('html title')->text || 'no title';
                $title = encode_utf8($title);
                $self->to_channel($cl, $channel, "[$title] - $shorten");
            };
    }
}

__PACKAGE__->meta->make_immutable;

1;
