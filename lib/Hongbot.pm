package Hongbot;
use AnyEvent;
use AnyEvent::IRC::Client;
use Moose;
use namespace::autoclean;
with 'MooseX::Role::Pluggable';

has condvar => (
    is => 'ro',
    lazy_build => 1,
);

has name => (
    is => 'ro',
    isa => 'Str',
    default => 'hongbot',
    writer => '_name',
);

has channels => (
    is => 'ro',
    isa => 'ArrayRef',
    default => sub { [] },
);

has irc_client => (
    is => 'ro',
    isa => 'AnyEvent::IRC::Client',
    lazy_build => 1,
);

sub _build_condvar { AnyEvent->condvar }
sub _build_irc_client {
    my $self = shift;

    my $irc = AnyEvent::IRC::Client->new();
    $irc->reg_cb(
        connect => sub {
            my ($con, $err) = @_;
            if (defined $err) {
                warn "connect error: $err\n";
                return;
            }

            $irc->send_srv(JOIN => $_) for (@{ $self->channels });
            $self->event('connect');
        },
    );
    $irc->reg_cb(
        join => sub {
            my ($cl, $nick, $channel, $is_myself) = @_;
            $self->_name($cl->nick) if $is_myself;
            $self->event('join', $cl, $nick, $channel, $is_myself);
        }
    );
    $irc->reg_cb(
        part => sub {
            my ($cl, $nick, $channel, $is_myself, $msg) = @_;
            $self->event('part', $cl, $nick, $channel, $is_myself, $msg);
        }
    );

    $irc->reg_cb(
        quit => sub {
            my ($cl, $nick, $msg) = @_;
            $self->event('quit', $cl, $nick, $msg);
        }
    );

    $irc->reg_cb(
        publicmsg => sub {
            my ($cl, $channel, $ircmsg) = @_;

            my ($nickname, $msg) = $self->parse_msg($ircmsg);
            return if $nickname eq $self->name; # loop guard

            my $bot_name = $self->name;
            if ($msg =~ m/^\s*$bot_name/) {
                $msg =~ s/^\s*$bot_name\s*:?\s*//;
                $self->event('respond', $cl, $channel, $nickname, $msg);
            } else {
                $self->event('hear', $cl, $channel, $nickname, $msg);
            }
        }
    );

    $irc->reg_cb(
        privatemsg => sub {
            my ($cl, $nick, $ircmsg) = @_;
            $self->event('privatemsg', $cl, $nick, $ircmsg);
        }
    );

    return $irc;
}

sub parse_msg {
    my ($self, $irc_msg) = @_;

    my ($nickname) = $irc_msg->{prefix} =~ m/^([^!]+)/;
    my $message = $irc_msg->{params}[1];
    return ($nickname, $message);
}

sub run {
    my ($self, $connect_info) = @_;
    $self->condvar->begin;

    $self->irc_client->connect(
        $connect_info->{host},
        $connect_info->{port},
        {
            nick => $self->name
        }
    );

    $self->condvar->recv;
}

sub event {
    my ($self, $event, @args) = @_;

    foreach my $plugin ( @{ $self->plugin_list } ) {
        $plugin->$event(@args) if $plugin->can($event);
    }
}

__PACKAGE__->meta->make_immutable;

1;
