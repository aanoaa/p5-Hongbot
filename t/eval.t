use strict;
use warnings;
use AnyEvent::IRC::Client;
use Hongbot;
use Hongbot::Plugin::Eval;
use Test::MockObject::Extends;
use Test::More;

my $client = new AnyEvent::IRC::Client;
$client = Test::MockObject::Extends->new($client);

# channel, nickanme, message
my @args = ('#hongbot', 'hshong', 'eval print $^V;');

my $robot = Hongbot->new;
$client->mock(
    'send_srv', sub {
        my ($self, $cmd, $channel, $msg) = @_;

        if ($msg =~ m/^stdout/) {
            like($msg, qr/^stdout: v5/, 'evaluated');
            $robot->condvar->send;
        }
    }
);

my $greet = Hongbot::Plugin::Eval->new({
    name => 'Hello',
    parent => $robot,
});

$greet->respond($client, @args);
$robot->condvar->recv;

done_testing();
