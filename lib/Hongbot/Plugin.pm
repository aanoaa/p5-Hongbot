package Hongbot::Plugin;
use Moose;
use Time::HiRes;
use namespace::autoclean;

has _COMMAND => (is => 'ro', isa => 'Str', default => 'PRIVMSG');

has regex => (
    is => 'ro',
    isa => 'RegexpRef',
    writer => '_regex',
    default => sub { qr// },
);

sub rm_prefix {
    my ($self, $regex, $msg) = @_;

    return unless $msg =~ m/$regex/;

    $msg =~ s/$regex//;
    return $msg;
}

sub to_channel {
    my ($self, $cl, $channel, $body) = @_;

    for my $line (split /\n/, $body) {
        $cl->send_srv($self->_COMMAND, $channel, $line);
        Time::HiRes::sleep(0.1);
    }
}

__PACKAGE__->meta->make_immutable;

1;
