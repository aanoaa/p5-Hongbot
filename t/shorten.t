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
#my $euckr = 'http://news.mk.co.kr/v2/view.php?sc=30500003&cm=%EC%82%AC%EC%84%A4&year=2012&no=1386&selFlag=&relatedcode=&wonNo=&sID=300';

my $euckr = 'http://review.auction.co.kr/Feedback/FeedbackView.aspx?orderNo=656350315&category=09180100&itemNo=A562360174';
#my $euckr = $utf8;
my $image = "https://secure.gravatar.com/avatar/6e828df5d001a64887e4060cad244029?s=140&d=https://a248.e.akamai.net/assets.github.com%2Fimages%2Fgravatars%2Fgravatar-140.png";
my @args = ('#hongbot', 'hshong', $utf8);

my $robot = Hongbot->new;
$client->mock(
    'send_srv', sub {
        my ($self, $cmd, $channel, $msg) = @_;
        diag($msg);
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

pop @args;
push @args, $image;
$robot->condvar->begin;
$greet->hear($client, @args);
$robot->condvar->recv;

done_testing();
