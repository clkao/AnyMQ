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

sub BUILD {
    my $self = shift;
    $self->id('AnyMQ-'.refaddr($self)) unless $self->id;
}

sub append {
    my($self, @messages) = @_;

    if ($self->{cv}->cb) {
        # currently listening: flush and send the events right away
        $self->_flush(@messages);
    } else {
        # between long poll comet: buffer the events
        push @{$self->{buffer}}, @messages;
    }
}

sub subscribe {
    my ($self, $topic) = @_;
    $topic->add_subscriber($self);
}

sub _flush {
    my($self, @messages) = @_;

    try {
        my $cb = $self->{cv}->cb;
        $self->{cv}->send(@messages);
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
        $self->_flush;
    };
    weaken $self->{timer};

    # flush buffer for a long-poll client
    $self->_flush( @{ $self->{buffer} })
        if @{ $self->{buffer} };
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

  my $channel = AnyMQ->topic('Foo');
  my $client = AnyMQ->new_listener($channel);

  $client->poll_once(sub {
      my @messages = @_;
      # ...
  });

  $client->poll(sub {
      my @messages = @_;
      # ...
  });

=head1 DESCRIPTION

An AnyMQ::Queue instance is a queue, each message put into the queue
can be consumed exactly once.  It's used as the client (or the
subscriber in terms of pub/sub) in L<AnyMQ>.  An AnyMQ::Queue can
subscribe to multiple L<AnyMQ::Topic>.

=head1 METHODS

=head2 subscribe($topic)

Subscribe to a L<AnyMQ::Topic> object.

=head2 poll($code_ref)

This is the event-driven poll mechanism, which accepts a callback.
Messages are streamed to C<$code_ref> passed in.

=head2 poll_once($code_ref)

This method returns all messages since the last poll to C<$code_ref>.

=head2 append(@messages)

Append messages directly to the queue.  You probably want to use
C<publish> method of L<AnyMQ::Topic>


=head1 SEE ALSO

L<AnyMQ> L<AnyMQ::Topic>

=cut
