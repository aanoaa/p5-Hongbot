use strict;
use warnings;
use AnyEvent::IRC::Client;
use Hongbot;
use Hongbot::Plugin::Twitter;
use Test::MockObject::Extends;
use Test::More;

my $client = new AnyEvent::IRC::Client;
$client = Test::MockObject::Extends->new($client);

# channel, nickanme, message
my @args = ('#hongbot', 'hshong', 'https://twitter.com/miyagawa/status/207772109223641088');

my $robot = Hongbot->new;
$client->mock(
    'send_srv', sub {
        my ($self, $cmd, $channel, $msg) = @_;
        like($msg, qr/yup/, "miyagawa's metion");
        $robot->condvar->send;
    }
);

my $greet = Hongbot::Plugin::Twitter->new({
    name => 'Twitter',
    parent => $robot,
});

$greet->hear($client, @args);
$robot->condvar->recv;

done_testing();

#https://twitter.com/miyagawa/status/207772109223641088
