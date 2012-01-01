package Hongbot::Plugin::Eval;
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
    default => sub { URI->new("http://api.dan.co.jp/lleval.cgi") },
);

has prefix => (is => 'ro', isa => 'Str', default => "#!/usr/bin/perl\n");

override 'usage' => sub { sprintf("%s: eval <PERL_CODE>", $_[0]->parent->name) };
override 'regex' => sub { qr/^eval\s+/i };

sub respond {
    my ($self, $cl, $channel, $nickname, $msg) = @_;

    $msg = $self->rm_prefix($self->regex, $msg);
    return unless $msg;

    $msg = $self->prefix . $msg;
    $self->uri->query_form(s => $msg);
    my $guard; $guard = http_get $self->uri, sub {
        undef $guard;
        my ($body, $headers) = @_;
        if ($headers->{Status} =~ m/^2/) {
            my $scalar = JSON::from_json($body);
            my @eval;
            map { push @eval, "$_: $scalar->{$_}" } qw/lang status stderr stdout syscalls time/;
            $self->to_channel($cl, $channel, @eval);
        } else {
            $self->to_channel($cl, $channel, sprintf("httpCode: %d", $headers->{Status}));
        }
    };
}

__PACKAGE__->meta->make_immutable;

1;
