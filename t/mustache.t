use strict;
use warnings;
use AnyEvent::IRC::Client;
use Hongbot;
use Hongbot::Plugin::Mustache;
use Test::MockObject::Extends;
use Test::More;

my $client = new AnyEvent::IRC::Client;
$client = Test::MockObject::Extends->new($client);

# channel, nickanme, message
my @args = ('#hongbot', 'hshong', 'mustache jeen');

my $robot = Hongbot->new;
$client->mock(
    'send_srv', sub {
        my ($self, $cmd, $channel, $msg) = @_;
        like($msg, qr/^http/, 'mustachify');
        $robot->condvar->send;
    }
);

my $greet = Hongbot::Plugin::Mustache->new({
    name => 'Mustache',
    parent => $robot,
});

$greet->respond($client, @args);
$robot->condvar->recv;

done_testing();
