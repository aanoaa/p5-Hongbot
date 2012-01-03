package Hongbot::Plugin::Shorten;
use URI;
use Moose;
use Mojo::DOM;
use File::Temp;
use AnyEvent::HTTP;
use Encode qw(decode encode_utf8);
use WWW::Shorten 'TinyURL';
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

        if ($uri->host =~ m/twitter/i) {
            my $plist = $self->parent->plugin_list;
            return if ($plist && grep { /twitter/i } @$plist);
        }

        if (length "$uri" > 50 && $uri->authority !~ /tinyurl|bit\.ly/) {
            $shorten = URI->new(makeashorterlink($uri))
        } else {
            $shorten = $uri;
        }

        my $file;
        my $is_html;
        my $guard; $guard = http_get $uri,
            on_header => sub {
                my ($headers) = @_;

                if (!$headers->{Status} =~ m/^2/) {
                    $self->to_channel($cl, $channel, sprintf("httpCode: %d", $headers->{Status}));
                    return;
                }

                $is_html = 1 if $headers->{'content-type'} =~ m/html/i;
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
                my $octets = do { local $/; <$file> };
                my $charset = 'utf8';
                if ($octets =~ /charset=(?:'([^']+?)'|"([^"]+?)"|([a-zA-Z0-9_-]+)\b)/) {
                    $charset = lc($1 || $2 || $3 || 'utf8');
                }

                my $data = decode($charset, $octets);
                my $dom = Mojo::DOM->new($data);
                $dom->charset($charset);
                my $title = $dom->at('html title')->text || 'no title';
                $title = encode_utf8($title);
                $self->to_channel($cl, $channel, "[$title] $shorten");
            };
    }
}

__PACKAGE__->meta->make_immutable;

1;
