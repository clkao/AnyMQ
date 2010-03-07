package AnyMQ::Queue;
use Moose;
use AnyEvent;
use Try::Tiny;
use Scalar::Util qw(weaken refaddr);
use Time::HiRes;
use constant DEBUG => 0;

has id => (is => 'rw', isa => 'Str');
has persistent => (is => "rw", isa => "Bool", default => sub { 0 });
has buffer => (is => "ro", isa => "ArrayRef", default => sub { [] });
has cv => (is => "rw", isa => "AnyEvent::CondVar", default => sub { AE::cv });
has destroyed => (is => "rw", isa => "Bool", default => sub { 0 });

my %instances;

sub BUILD {
    my $self = shift;
    $self->id('AnyMQ-'.refaddr($self)) unless $self->id;
}

sub instance {
    my($class, $name, @mq) = @_;
    warn "deprecated, use ->new_listener()";
    $name ||= rand(1);
    my $self = $instances{$name} ||= $class->new;
    $self->subscribe($_) for @mq;

    return $self;
}

sub publish {
    my($self, @events) = @_;

    if ($self->{cv}->cb) {
        # currently listening: flush and send the events right away
        $self->flush_events(@events);
    } else {
        # between long poll comet: buffer the events
        push @{$self->{buffer}}, @events;
    }
}

sub subscribe {
    my ($self, $mq) = @_;
    $mq->subscribe($self);
}

sub flush_events {
    my($self, @events) = @_;

    try {
        my $cb = $self->{cv}->cb;
        $self->{cv}->send(@events);
        $self->{cv} = AE::cv;
        $self->{buffer} = [];

        if ($self->{persistent}) {
            $self->{cv}->cb($cb);
        } else {
            $self->{timer} = AE::timer 30, 0, sub {
                weaken $self;
                warn "Sweep $self (no long-poll reconnect)";
                undef $self;
                # XXX: unsubscribe from all AnyMQ
#                delete $self->clients->{$self_id};
            };
            weaken $self->{timer};
        }
    } catch {
        warn $_;
        $self->destroyed(1);
    };
}

sub poll_once {
    my($self, $cb, $timeout) = @_;

    warn "already polled by another client" if $self->persistent;

    $self->{cv}->cb(sub { $cb->($_[0]->recv) });

    # reset garbage collection timeout with the long-poll timeout
    # $timeout = 0 is a valid timeout for interval-polling
    $timeout = 55 unless defined $timeout;
    $self->{timer} = AE::timer $timeout || 55, 0, sub {
        weaken $self;
        warn "Timing out $self long-poll" if DEBUG;
        $self->flush_events;
    };
    weaken $self->{timer};

    # flush buffer for a long-poll client
    $self->flush_events( @{ $self->{buffer} });
}

sub poll {
    my($self, $cb) = @_;
    $self->cv->cb(sub { $cb->($_[0]->recv) });
    $self->persistent(1);
}


__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__

=encoding utf-8

=for stopwords

=head1 NAME

AnyMQ::Queue - AnyMQ Message Queue

=head1 SYNOPSIS

To publish a message, you first create an instance of the AnyMQ on a
specific channel, and an L<AnyMQ::Queue> instance that subscribes to
it:

    my $mq = AnyMQ->instance($channel);
    my $client = AnyMQ::Queue->instance('client_id', $mq);

Later, you can poll for new messages:

    $client->poll_once( sub { warn "got message: $_[0]"; } );

    $client->poll(sub {
        my @events = @_;
        for my $event (@events) {
            $self->stream_write($event);
        }
    });

=head1 DESCRIPTION

An AnyMQ::Queue instance is a queue, each message put into the queue
can be consumed once.  It's used as the client to L<AnyMQ>.  An
AnyMQ::Queue can subscribe to multiple L<AnyMQ>.

=head1 CONFIGURATION

=over

=item BacklogLength

To configure the number of messages in the backlog, set 
C<$AnyMQ::Queue::BacklogLength>.  By default, this is set to 30.

=back

=head1 METHODS

=head2 publish

This method publishes a message into the message queue, for immediate 
consumption by all polling clients.

=head2 poll($client_id, $code_ref)

This is the event-driven poll mechanism, which accepts a callback as the
second parameter. It will stream messages to the code ref passed in. 

=head2 poll_once($client_id, $code_ref)

This method returns all messages since the last poll to the code reference
passed as the second parameter.

=head1 AUTHOR

Tatsuhiko Miyagawa

Chia-liang Kao

=head1 SEE ALSO

L<Tatsumaki>

=cut
