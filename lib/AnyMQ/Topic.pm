package AnyMQ::Topic;

use strict;
use 5.008_001;
our $VERSION = '0.01';

use AnyEvent;
use Any::Moose;
use Try::Tiny;
use Scalar::Util;
use Time::HiRes;
use constant DEBUG => 0;

has name => (is => 'rw', isa => 'Str');
has bus => (is => "ro", isa => "AnyMQ", weak_ref => 1);
has queues  => (is => 'rw', isa => 'HashRef',  default => sub { +{} });

sub publish {
    my($self, @events) = @_;
    for my $queue (values %{$self->queues}) {
        if ($queue->destroyed) {
            delete $self->queues->{$queue->name};
            next;
        }

        $queue->publish(@events);
    }
}

sub subscribe {
    my ($self, $queue) = @_;
    $self->queues->{$queue->id} = $queue;
}

__PACKAGE__->meta->make_immutable;
no Any::Moose;
1;
