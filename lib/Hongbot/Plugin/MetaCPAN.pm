package Hongbot::Plugin::MetaCPAN;
use URI;
use Moose;
use AnyEvent::HTTP;
use namespace::autoclean;
extends 'Hongbot::Plugin';
with 'MooseX::Role::Pluggable::Plugin';

has uri => (
    is => 'ro',
    isa => 'URI',
    default => sub { URI->new("https://metacpan.org/module/") },
);

override 'usage' => sub { "cpan <Module::Name>" };
override 'regex' => sub { qr/^cpan\s+/i };

sub hear {
    my ($self, $cl, $channel, $nickname, $query) = @_;

    $query = $self->rm_prefix($self->regex, $query);
    return unless $query;

    my @modules = map { "@{[ $self->uri->as_string ]}$_" } split(/\s+/, $query);
    $self->to_channel($cl, $channel, @modules);
}

__PACKAGE__->meta->make_immutable;

1;
