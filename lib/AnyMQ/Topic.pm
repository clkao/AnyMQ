package AnyMQ::Topic;

use strict;
use 5.008_001;
our $VERSION = '0.01';

use AnyEvent;
use Any::Moose;
use Try::Tiny;
use Scalar::Util;
use Time::HiRes;

with any_moose("X::Traits");

has name => (is => 'rw', isa => 'Str');
has bus => (is => "ro", isa => "AnyMQ", weak_ref => 1);
has queues => (traits => ['Hash'],
               is => 'rw',
               isa => 'HashRef',
               default => sub { {} },
               handles => {
                   add_listener      => 'set',
                   has_no_listeners  => 'is_empty',
               }
           );
has recycle => (is => "rw", isa => "Bool", default => sub { 0 });
has 'reaper_interval' => (is => 'ro', isa => 'Int', default => sub { 30 });
has 'publish_to_queues' => (is => 'rw', isa => 'Bool', default => sub { 1 });
has '_listener_reaper' => (is => 'rw');
has '+_trait_namespace' => (default => 'AnyMQ::Topic::Trait');

sub BUILD {
    my $self = shift;
    $self->install_reaper if $self->reaper_interval;
}

sub install_reaper {
    my $self = shift;

    $self->_listener_reaper(
        AnyEvent->timer(interval => $self->reaper_interval,
                        cb => sub { $self->reap_destroyed_listeners })
    );
}

sub reap_destroyed_listeners {
    my $self = shift;
    return if $self->has_no_listeners;
    $self->remove_subscriber($_)
        for grep { $_->destroyed } values %{$self->queues};

    if ($self->recycle && $self->has_no_listeners) {
        delete $self->bus->topics->{$self->name};
    }
}

sub publish {
    my ($self, @messages) = @_;
    $self->append_to_queues(@messages) if $self->publish_to_queues;
    $self->dispatch_messages(@messages);
}

sub dispatch_messages {
    my ($self, @messages) = @_;
}

sub append_to_queues {
    my ($self, @messages) = @_;
    $self->reap_destroyed_listeners;
    for (values %{$self->queues}) {
        $_->append(@messages);
    }
    $self->install_reaper if $self->reaper_interval;
}

sub add_subscriber {
    my ($self, $queue) = @_;
    $self->add_listener($queue->id, $queue);
}

sub remove_subscriber {
    my ($self, $queue) = @_;
    delete $self->queues->{$queue->id};
}

__PACKAGE__->meta->make_immutable;
no Any::Moose;
1;

=encoding utf-8

=for stopwords

=head1 NAME

AnyMQ::Topic - AnyMQ Topic

=head1 SYNOPSIS

  my $channel = AnyMQ->topic('Foo');
  my $client = AnyMQ->new_listener($channel);

=head1 DESCRIPTION

An AnyMQ::Topic instance is a topic where messages can be published
to, and L<AnyMQ::Queue> objects can subscribe to.  each message
published to the topic will be appended to each subscribing queue.

=head1 ATTRIBUTES

=head2 recycle

True if the topic should be recycled once all listeners are gone.

=head2 reaper_interval

Interval in seconds that destroyed listeners to this topic should be
reaped and freed.

=head1 METHODS

=head2 publish(@messages)

Publish messages to the topic.

=head2 add_subscriber($queue)

Add a new listener to the topic.

=head1 SEE ALSO

L<AnyMQ> L<AnyMQ::Queue>

=cut
