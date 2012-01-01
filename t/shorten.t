use strict;
use warnings;
use utf8;
use AnyEvent::IRC::Client;
use Hongbot;
use Hongbot::Plugin::Shorten;
use Test::MockObject::Extends;
use Test::More;

my $client = new AnyEvent::IRC::Client;
$client = Test::MockObject::Extends->new($client);

# channel, nickanme, message
my $utf8 = 'http://search.cpan.org/~tempire/Mojolicious-2.41/lib/Mojo/DOM.pm';
my $euckr = 'http://news.mk.co.kr/v2/view.php?sc=30500003&cm=%EC%82%AC%EC%84%A4&year=2012&no=1386&selFlag=&relatedcode=&wonNo=&sID=300';
my @args = ('#hongbot', 'hshong', $utf8);

my $robot = Hongbot->new;
$client->mock(
    'send_srv', sub {
        my ($self, $cmd, $channel, $msg) = @_;

        like($msg, qr/tinyurl/, 'contained tinyurl');
        $robot->condvar->end;
    }
);

my $greet = Hongbot::Plugin::Shorten->new({
    name => 'Shorten',
    parent => $robot,
});

$robot->condvar->begin;
$greet->hear($client, @args);
pop @args;
push @args, $euckr;
$robot->condvar->begin;
$greet->hear($client, @args);
$robot->condvar->recv;

done_testing();
