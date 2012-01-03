package Hongbot::Plugin::Map;
use URI;
use JSON;
use Moose;
use AnyEvent::HTTP;
use namespace::autoclean;
extends 'Hongbot::Plugin';
with 'MooseX::Role::Pluggable::Plugin';

has uri => (
    is => 'ro',
    isa => 'URI',
    default => sub { URI->new("http://maps.google.com/maps") },
);

override 'usage' => sub { sprintf("%s: map <query>", $_[0]->parent->name) };
override 'regex' => sub { qr/^map\s+/i };

sub respond {
    my ($self, $cl, $channel, $nickname, $query) = @_;

    $query = $self->rm_prefix($self->regex, $query);
    return unless $query;

    $self->uri->query_form({
        q => $query,
        hl => 'ko',
        sll => '37.530029,127.077435',
        vpsrc => 0,
        hnear => $query,
        t => 'm',
        z => 17,
    });

    $self->to_channel($cl, $channel, $self->uri->as_string);
}

__PACKAGE__->meta->make_immutable;

1;
