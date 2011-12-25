package Hongbot::Plugin;
use Moose;
use namespace::autoclean;

has regex => (
    is => 'ro',
    isa => 'RegexpRef',
    writer => '_regex',
    default => sub { qr// },
);

sub rm_prefix {
    my ($self, $regex, $msg) = @_;

    return unless $msg =~ m/$regex/;

    $msg =~ s/$regex//;
    return $msg;
}

__PACKAGE__->meta->make_immutable;

1;
