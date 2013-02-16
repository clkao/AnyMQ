package AnyMQ::Queue;
use strict;
use Any::Moose;
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
has on_timeout => (is => "rw");
has on_error  => (is => "rw");
has timeout => (is => "rw", isa => "Int", default => sub { 55 });

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
    Carp::cluck unless $topic;
    $topic->add_subscriber($self);
}

sub _flush {
    my ($self, @messages) = @_;

    my $cb = $self->{cv}->cb;
    my $cv = $self->{cv};
    $self->{cv} = AE::cv;
    $self->{buffer} = [];

    try {
        $cv->send(@messages);
    } catch {
        if ($self->on_error) {
            $self->on_error->($self, $_, @messages);
        }
        else {
            $self->destroyed(1);
        }
    };

    return if $self->destroyed;

    if ($self->{persistent}) {
        $self->{cv}->cb($cb);
        $self->_flush( @{ $self->{buffer} })
            if @{ $self->{buffer} };
    } else {
        $self->{timer} = $self->_reaper;
    }

}

sub _reaper {
    my ($self, $timeout) = @_;

    AnyEvent->timer(
        after => $timeout || $self->timeout,
        cb => sub {
            weaken $self;
            warn "Timing out $self long-poll" if DEBUG;
            if ($self->on_timeout) {
                $self->on_timeout->($self, "timeout")
            }
            else {
                $self->destroyed(1);
            }
        });
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
        warn "long-poll timeout, flush and wait for client reconnect" if DEBUG;
        $self->_flush;
    };
    weaken $self->{timer};

    # flush buffer for a long-poll client
    $self->_flush( @{ $self->{buffer} })
        if @{ $self->{buffer} };
}

sub poll {
    my ($self, $cb) = @_;
    $self->cv->cb(sub { $cb->($_[0]->recv) });
    $self->persistent(1);

    undef $self->{timer};

    $self->_flush( @{ $self->{buffer} })
        if @{ $self->{buffer} };
}

sub unpoll {
    my $self = shift;
    $self->cv->cb(undef);
    $self->persistent(0);
    $self->{timer} = $self->_reaper;
}

__PACKAGE__->meta->make_immutable;
no Any::Moose;
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

=head2 unpoll

Cancels a running L</poll>, which will result in L</on_timeout> being
called.

=head2 poll_once($code_ref, $timeout)

This method returns all messages since the last poll to C<$code_ref>.
It blocks for C<$timeout> seconds if there's currently no messages
available.

=head2 destroyed(BOOL)

Marking the current queue as destroyed or not.

=head2 timeout($seconds)

Timeout value for this queue.  Default is 55.

=head2 on_error(sub { my ($queue, $error, @msg) = @_; ... })

Sets the error handler invoked when C<poll> or C<poll_once> callbacks
fail.  By default the queue is marked as destroyed.  If you register
this error handler, you should call C<< $queue->destroyed(1) >> should you
wish to mark the queue as destroyed and reclaim resources.

Note that for queues that are currently C<poll>'ed, you may unset the
C<persistent> attribute to avoid the queue from being destroyed, and
can be used for further C<poll> or C<poll_once> calls.  In this case,
C<on_timeout> will be triggered if C<poll> or C<poll_once> is not
called after C<< $self->timeout >> seconds.

=head2 on_timeout(sub { my ($queue, $error) = @_; ... })

If a queue is not currently polled, this callback will be triggered
after C<< $self->timeout >> seconds.  The default behaviour is marking the
queue as destroyed.

=head2 append(@messages)

Append messages directly to the queue.  You probably want to use
C<publish> method of L<AnyMQ::Topic>

=head1 SEE ALSO

L<AnyMQ> L<AnyMQ::Topic>

=cut
