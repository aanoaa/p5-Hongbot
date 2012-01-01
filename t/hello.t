use strict;
use warnings;
use AnyEvent::IRC::Client;
use Hongbot;
use Hongbot::Plugin::Hello;
use Test::MockObject::Extends;
use Test::More;

my $client = new AnyEvent::IRC::Client;
$client = Test::MockObject::Extends->new($client);

# channel, nickanme, message
my @args = ('#hongbot', 'hshong', 'hello');

my $robot = Hongbot->new;
$client->mock(
    'send_srv', sub {
        my ($self, $cmd, $channel, $msg) = @_;

        like($msg, qr/hshong/, 'check nickname');
        like($msg, qr/hello/, 'check message');
        $robot->condvar->send;
    }
);

my $greet = Hongbot::Plugin::Hello->new({
    name => 'Hello',
    parent => $robot,
});

$greet->respond($client, @args);
$robot->condvar->recv;

done_testing();
