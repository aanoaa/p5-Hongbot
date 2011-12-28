#!/usr/bin/env perl
use strict;
use warnings;
use AnyEvent::IRC::Client;
use Hongbot;
use Hongbot::Plugin::Ascii;
use Test::MockObject::Extends;
use Test::More;

my $client = new AnyEvent::IRC::Client;
$client = Test::MockObject::Extends->new($client);

my @args = ('#hongbot', 'hshong', 'ascii hello world');

my $i = 0;
my $letter;
my $robot = Hongbot->new;
$client->mock(
    'send_srv', sub {
        my ($self, $cmd, $channel, $msg) = @_;

        if ($i == 0) {
            is($cmd, 'PRIVMSG', 'cmd');
            like($msg, qr/ascii/, 'help msg');
        } else {
            $letter .= "$msg\n";
        }

        $i++;
        $robot->condvar->send if $i > 1;
        if ($i > 8) {
            diag($letter);
            diag('pass if you see this');
        }
    }
);

my $ascii = Hongbot::Plugin::Ascii->new({
    name => 'Ascii',
    parent => $robot,
});

ok($ascii->can('help'));
ok($ascii->can('hear'));

$ascii->help($client, @args);
$ascii->hear($client, @args);
$robot->condvar->recv;

done_testing();
