package Hongbot::Plugin;
use Moose;
use URI;
use Time::HiRes;
use WWW::Shorten 'TinyURL';
use namespace::autoclean;

has _COMMAND => (is => 'ro', isa => 'Str', default => 'PRIVMSG');

has regex => (
    is => 'ro',
    isa => 'RegexpRef',
    writer => '_regex',
    default => sub { qr// },
);

has usage => (
    is => 'ro',
    isa => 'Str',
    default => '',
);

sub rm_prefix {
    my ($self, $regex, $msg) = @_;

    return unless $msg =~ m/$regex/;

    $msg =~ s/$regex//;
    return $msg;
}

sub to_channel {
    my ($self, $cl, $channel, @body) = @_;

    for my $body (@body) {
        for my $line (split /\n/, $body) {
            if ($line =~ m/^http/) {
                my $uri = URI->new($line);
                my $shorten_url;
                if (length "$uri" > 50 && $uri->authority !~ /tinyurl|bit\.ly/) {
                    $shorten_url = makeashorterlink($uri);
                    $uri = URI->new($shorten_url);
                    $cl->send_srv($self->_COMMAND, $channel, $uri->as_string);
                }
            } else {
                $cl->send_srv($self->_COMMAND, $channel, $line);
            }

            Time::HiRes::sleep(0.1);
        }
    }
}

sub help {
    my ($self, $cl, $channel) = @_;

    $self->to_channel($cl, $channel, sprintf("Usage: [%s]", $self->usage)) if $self->usage ne '';
}

__PACKAGE__->meta->make_immutable;

1;
