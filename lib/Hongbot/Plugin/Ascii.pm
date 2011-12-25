package Hongbot::Plugin::Ascii;
use URI;
use Moose;
use Time::HiRes;
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
                for my $line (split /\n/, $body) {
                    $cl->send_srv('PRIVMSG', $channel, $line);
                    Time::HiRes::sleep(0.1);
                }
            }
        };
    }
}

sub help {
    my ($self, $cl, $channel) = @_;

    $cl->send_srv('PRIVMSG', $channel, $self->usage);
}

__PACKAGE__->meta->make_immutable;

1;
