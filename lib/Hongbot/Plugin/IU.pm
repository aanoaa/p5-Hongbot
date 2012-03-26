package Hongbot::Plugin::IU;
use utf8;
use AnyEvent;
use Net::Twitter;
use Scalar::Util 'blessed';
use DateTime;
use DateTime::Format::Strptime;
use Encode qw/encode_utf8/;
use Moose;
use namespace::autoclean;
extends 'Hongbot::Plugin';
with 'MooseX::Role::Pluggable::Plugin';

my $interval = 60;

has timer => (
    is => 'ro',
    isa => 'Any',
    writer => '_timer',
);

has parser => (
    is => 'ro',
    isa => 'DateTime::Format::Strptime',
    default => sub {
        DateTime::Format::Strptime->new(
            pattern => '%A %B %d %H:%M:%S %z %Y',
            on_error => 'croak',
        );
    }
);

sub join {
    my ($self, $cl, $nick, $channel, $is_myself) = @_;

    warn "joinned $channel";

    my $twitter = Net::Twitter->new(
        traits   => [qw/OAuth API::REST/],
        consumer_key        => $ENV{HONGBOT_TWITTER_COSUMER_KEY},
        consumer_secret     => $ENV{HONGBOT_TWITTER_COSUMER_SECRET},
        access_token        => $ENV{HONGBOT_TWITTER_ACCESS_TOKEN},
        access_token_secret => $ENV{HONGBOT_TWITTER_ACCESS_TOKEN_SECRET},
    );

    $self->_timer(
        AnyEvent->timer(
            after => 1,
            interval => $interval,
            cb => sub {
                my $dt = DateTime->now;
                eval {
                    my $statuses = $twitter->user_timeline({ id => 'lily199iu', count => 10 });
                    for my $status ( @$statuses ) {
                        my $created_at = $self->parser->parse_datetime($status->{created_at});
                        last if ($dt->epoch - $created_at->epoch) > $interval;

                        $self->to_channel(
                            $cl,
                            $channel,
                            encode_utf8("<$status->{user}{screen_name}> $status->{text}")
                        );
                    }
                };

                if ( my $err = $@ ) {
                    die $@ unless blessed $err && $err->isa('Net::Twitter::Error');
                    $self->to_channel($cl, $channel, $err->message);
                }
            },
        )
    );
}

__PACKAGE__->meta->make_immutable;

1;
