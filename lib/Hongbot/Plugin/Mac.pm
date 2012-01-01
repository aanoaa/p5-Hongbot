package Hongbot::Plugin::Mac;
use utf8;
use Moose;
use Encode qw/decode_utf8 encode_utf8/;
use Lingua::KO::Hangul::Util qw(:all);
use namespace::autoclean;
extends 'Hongbot::Plugin';
with 'MooseX::Role::Pluggable::Plugin';

my $JONGSUNG_BEGIN    = 0x11A8;
my $JONGSUNG_END      = 0x11FF;
my $JONGSUNG_DIGEUG   = 0x11AE; # ㄷ
my $JONGSUNG_BIEUP    = 0x11B8; # ㅂ
my $JONGSUNG_JIEUT    = 0x11BD; # ㅈ
my $SELLABLE_BEGIN    = 0x3131;
my $INTERVAL          = $SELLABLE_BEGIN - $JONGSUNG_BEGIN;

override 'usage' => sub { sprintf("%s: mac <macboogify>", $_[0]->parent->name) };
override 'regex' => sub { qr/^mac(?:boogi)?\s+/i };

sub respond {
    my ($self, $cl, $channel, $nickname, $msg) = @_;

    $msg = $self->rm_prefix($self->regex, $msg);
    return unless $msg;

    $msg = decode_utf8(uc $msg);
    my @chars = split //, $msg;
    my @mac_chars;
    for my $char (@chars) {
        my $ord = ord $char;
        if ($ord >= 65 && $ord <= 90) {
            push @mac_chars, $char;
            next;
        }

        my @jamo = split //, decomposeSyllable($char);
        for (@jamo) {
            my $code = unpack 'U*', $_;
            if ($code >= $JONGSUNG_BEGIN && $code <= $JONGSUNG_DIGEUG) {
                $code += $INTERVAL;
            } elsif ($code > $JONGSUNG_DIGEUG && $code <= $JONGSUNG_BIEUP) {
                $code += $INTERVAL + 1;
            } elsif ($code > $JONGSUNG_BIEUP && $code <= $JONGSUNG_JIEUT) {
                $code += $INTERVAL + 2;
            } elsif ($code > $JONGSUNG_JIEUT && $code <= $JONGSUNG_END) {
                $code += $INTERVAL + 3;
            }

            $_ = pack 'U*', $code;
        }

        push @mac_chars, composeSyllable(join '', @jamo);
    }

    my $macboogify = join '', @mac_chars;
    $macboogify = encode_utf8($macboogify);
    $self->to_channel($cl, $channel, $macboogify);
}

__PACKAGE__->meta->make_immutable;

1;
