package Hongbot::Plugin::Youtube;
use URI;
use JSON;
use Moose;
use AnyEvent::HTTP;
use namespace::autoclean;
extends 'Hongbot::Plugin';
with 'MooseX::Role::Pluggable::Plugin';

has uri => (
    is => 'ro',
    isa => 'URI',
    default => sub { URI->new("http://gdata.youtube.com/feeds/api/videos") },
);

override 'usage' => sub { sprintf("%s: youtube <query>", $_[0]->parent->name) };
override 'regex' => sub { qr/^youtube\s+/i };

sub respond {
    my ($self, $cl, $channel, $nickname, $query) = @_;

    $query = $self->rm_prefix($self->regex, $query);
    return unless $query;

    $self->uri->query_form({
        orderBy => "relevance",
        'max-results' => 15,
        alt => 'json',
        q => $query,
    });

    my $guard; $guard = http_get $self->uri, sub {
        undef $guard;
        my ($body, $headers) = @_;
        if ($headers->{Status} =~ m/^2/) {
            my $scalar = JSON::from_json($body);
            my $videos = $scalar->{feed}{entry};
            my $video = $videos->[rand(@$videos)];
            for my $link (@{ $video->{link} }) {
                $self->to_channel($cl, $channel, $link->{href})
                    if $link->{rel} eq 'alternate' && $link->{type} eq 'text/html';
            }
        } else {
            $self->to_channel($cl, $channel, sprintf("httpCode: %d", $headers->{Status}));
        }
    };
}

__PACKAGE__->meta->make_immutable;

1;
