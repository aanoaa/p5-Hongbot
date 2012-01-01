use strict;
use warnings;
use Hongbot::Plugin;
use Test::More;

my $hp = Hongbot::Plugin->new;
$hp->_regex(qr/^ascii\s+/i);

isa_ok($hp, 'Hongbot::Plugin');
my $msg = $hp->rm_prefix($hp->regex, 'ascii oops');
is($msg, 'oops');

done_testing();
