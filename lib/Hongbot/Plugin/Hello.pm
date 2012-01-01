package Hongbot::Plugin::Hello;
use URI;
use Moose;
use AnyEvent::HTTP;
use namespace::autoclean;
extends 'Hongbot::Plugin';
with 'MooseX::Role::Pluggable::Plugin';

override 'usage' => sub { sprintf("%s: hello", $_[0]->parent->name) };
override 'regex' => sub { qr/^hello$/i };

sub respond {
    my ($self, $cl, $channel, $nickname, $msg) = @_;

    my $regex = $self->regex;
    $self->to_channel($cl, $channel, "hello $nickname") if $msg =~ m/$regex/;
}

__PACKAGE__->meta->make_immutable;

1;
