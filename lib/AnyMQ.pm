package AnyMQ;

use strict;
use 5.008_001;
our $VERSION = '0.01';

use AnyEvent;
use Any::Moose;
use Try::Tiny;
use Scalar::Util;
use Time::HiRes;
use constant DEBUG => 0;

has channel => (is => 'rw', isa => 'Str');
has queues  => (is => 'rw', isa => 'HashRef',  default => sub { +{} });

my %instances;

sub channels {
    values %instances;
}

sub instance {
    my($class, $name) = @_;
    $instances{$name} ||= $class->new(channel => $name);
}

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

1;
__END__

=encoding utf-8

=for stopwords

=head1 NAME

AnyMQ -

=head1 SYNOPSIS

  use AnyMQ;
  my $mq = AnyMQ->instance($channel);
  $mq->publish({ message => 'Hello world'});

=head1 DESCRIPTION

AnyMQ::Queue is a simple message queue based on AnyEvent, storing all
messages in memory or external mq.  polling requests are made with an
L<AnyMQ::Queue> instance> as its client, which keeps track of buffer
to ensure proper message delivery.

=head1 AUTHOR

Tatsuhiki Miyagawa

Chia-liang Kao

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
