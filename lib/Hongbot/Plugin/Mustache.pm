package Hongbot::Plugin::Mustache;
use URI;
use JSON;
use Moose;
use AnyEvent::HTTP;
use namespace::autoclean;
extends 'Hongbot::Plugin';
with 'MooseX::Role::Pluggable::Plugin';

has mustachify => (
    is => 'ro',
    isa => 'URI',
    default => sub { URI->new("http://mustachify.me/") },
);

has googleimage => (
    is => 'ro',
    isa => 'URI',
    default => sub { URI->new('http://ajax.googleapis.com/ajax/services/search/images') },
);

override 'usage' => sub { sprintf("%s: mustache <SEARCH WORD|IMG_URL>", $_[0]->parent->name) };
override 'regex' => sub { qr/^mustache\s+/i };

sub respond {
    my ($self, $cl, $channel, $nickname, $msg) = @_;

    $msg = $self->rm_prefix($self->regex, $msg);
    return unless $msg;

    if ($msg =~ m/^https?/) {
        $self->mustachify->query_form(src => $msg);
        $self->to_channel($cl, $channel, $self->mustachify->as_string);
    } else {
        $self->googleimage->query_form(v => '1.0', rsz => '8', q => $msg);
        my $guard; $guard = http_get $self->googleimage, sub {
            undef $guard;
            my ($body, $headers) = @_;
            if ($headers->{Status} =~ m/^2/) {
                my $results = JSON::from_json($body)->{responseData}{results};
                return unless @$results;

                my $rand = rand(@$results);
                my $uri = "$results->[$rand]{unescapedUrl}";
                $self->mustachify->query_form(src => $uri);
                $self->to_channel($cl, $channel, $self->mustachify->as_string);
            } else {
                $self->to_channel($cl, $channel, sprintf("httpCode: %d", $headers->{Status}));
            }
        };
    }
}

__PACKAGE__->meta->make_immutable;

1;
