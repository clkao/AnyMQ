package AnyMQ::Topic;

use strict;
use 5.008_001;
our $VERSION = '0.01';

use AnyEvent;
use Moose;
use Try::Tiny;
use Scalar::Util;
use Time::HiRes;

with 'MooseX::Traits';

has name => (is => 'rw', isa => 'Str');
has bus => (is => "ro", isa => "AnyMQ", weak_ref => 1);
has queues  => (is => 'rw', isa => 'HashRef',  default => sub { +{} });
has '+_trait_namespace' => (default => 'AnyMQ::Topic::Trait');

sub publish {
    my($self, @messages) = @_;
    for my $queue (values %{$self->queues}) {
        if ($queue->destroyed) {
            delete $self->queues->{$queue->id};
            next;
        }

        $queue->append(@messages);
    }
}

sub add_subscriber {
    my ($self, $queue) = @_;
    $self->queues->{$queue->id} = $queue;
}

__PACKAGE__->meta->make_immutable;
no Moose;
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

=head1 METHODS

=head2 publish(@messages)

Publish messages to the topic.

=head2 add_subscriber($queue)

Add a new listener to the topic.

=head1 SEE ALSO

L<AnyMQ> L<AnyMQ::Queue>

=cut
