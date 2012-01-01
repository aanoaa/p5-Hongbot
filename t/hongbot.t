use strict;
use warnings;
use Hongbot;
use AnyEvent::IRC::Client;
use Test::MockObject::Extends;
use Test::More;

my $robot = Hongbot->new(plugins => ['Ascii']);

isa_ok($robot, 'Hongbot');
ok($robot->does('MooseX::Role::Pluggable'), 'robot dose MX::R::P');
is($robot->name, 'hongbot', 'default name');
isa_ok($robot->channels, 'ARRAY');
isa_ok($robot->irc_client, 'AnyEvent::IRC::Client');

my $irc_msg = {
    'params' => [
        '#aanoaa',
        'oops'
    ],
    'command' => 'PRIVMSG',
    'prefix' => 'hshong!~user@211.201.233.219'
};

# parse_msg
my ($nickname, $message) = $robot->parse_msg($irc_msg);
is($nickname, 'hshong', 'parse nickname');
is($message, 'oops', 'parse public message');

# help
my $client = new AnyEvent::IRC::Client;
$client = Test::MockObject::Extends->new($client);
my $i = 0;
$client->mock(
    'send_srv', sub {
        my ($self, $cmd, $channel, $msg) = @_;

        if ($i == 0) {
            like($msg, qr/^hongbot: help <name>/, 'help usage');
            $i++;
            return;
        } elsif ($i == 1) {
            like($msg, qr/^ascii$/, 'help list');
            $i++;
            $robot->condvar->end;
        } else {
            like($msg, qr/^ascii/, 'each plugin help');
            $robot->condvar->end;
        }
    }
);

$robot->condvar->begin;
$robot->help($client, '#aanoaa');
# hongbot: help <name>
# <plugin_name>, <plugin_name>, ..

$robot->condvar->begin;
$robot->help($client, '#aanoaa', 'ascii');
# ascii <ASCII>
$robot->condvar->recv;

# run, event
done_testing();
