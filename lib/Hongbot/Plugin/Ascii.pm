package Hongbot::Plugin::Ascii;
use URI;
use Moose;
use AnyEvent::HTTP;
use namespace::autoclean;
extends 'Hongbot::Plugin';
with 'MooseX::Role::Pluggable::Plugin';

has uri => (
    is => 'ro',
    isa => 'URI',
    default => sub { URI->new("http://asciime.heroku.com/generate_ascii") },
);

has usage => (
    is => 'ro',
    isa => 'Str',
    default => 'ascii <ASCII>',
);

sub BUILD { shift->_regex(qr/^ascii\s+/i) }

sub hear {
    my ($self, $cl, $channel, $nickname, $msg) = @_;

    $msg = $self->rm_prefix($self->regex, $msg);

    if ($msg) {
        $self->uri->query_form(s => $msg);
        my $guard; $guard = http_get $self->uri, sub {
            undef $guard;
            my ($body, $headers) = @_;
            if ($headers->{Status} =~ m/^2/) {
                $self->to_channel($cl, $channel, $body);
            } else {
                $self->to_channel($cl, $channel, sprintf("httpCode: %d", $headers->{Status}));
            }
        };
    }
}

sub help {
    my ($self, $cl, $channel) = @_;

    $self->to_channel($cl, $channel, $self->usage);
}

__PACKAGE__->meta->make_immutable;

1;
