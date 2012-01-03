package Hongbot::Plugin::Twitter;
use URI;
use Moose;
use AnyEvent::HTTP;
use namespace::autoclean;
extends 'Hongbot::Plugin';
with 'MooseX::Role::Pluggable::Plugin';

override 'usage' => sub { 'https?://twitter.com/blahblah/' };
override 'regex' => sub { qr{(https?://(:?.*)twitter\.com/(:?[^/]+)/st\w+/[0-9]+)}i };

sub hear {
    my ($self, $cl, $channel, $nickname, $msg) = @_;

    $msg =~ s/#!\///;
    my $regex = $self->regex;
    my ($uri) = $msg =~ m/$regex/;
    return unless $uri;

    $uri = URI->new($uri);
    my $guard; $guard = http_get $uri, sub {
        undef $guard;
        my ($body, $headers) = @_;
        if ($headers->{Status} =~ m/^2/) {
            my ($tweet, $nick);
            if ($uri =~ /mobile\./i) {
                ($tweet) = $body =~ m{<span class="status">(.*)</span>}m;
                ($nick) = $uri =~ m{(\w+)/status};
                $tweet =~ s{<[^>]*>}{}g;
            } else {
                ($nick) = $body =~ m{<title id="page_title">Twitter / ([^:]*)};
                ($tweet) = $body =~ m{<meta content="([^"]*)" name="description" />}m;
            }

            $tweet =~ s/&amp;/&/g;
            $tweet =~ s/&lt;/</g;
            $tweet =~ s/&gt;/>/g;
            $tweet =~ s/&quot;/"/g;
            $tweet = $nick . ': ' . $tweet;
            $self->to_channel($cl, $channel, $tweet);
        } else {
            $self->to_channel($cl, $channel, sprintf("httpCode: %d", $headers->{Status}));
        }
    };
}

__PACKAGE__->meta->make_immutable;

1;
