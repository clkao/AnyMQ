package AnyMQ::Topic::Trait::WithBacklog;
use strict;
use Any::Moose "::Role";

has backlog_length => (is => "rw", isa => "Int", default => sub { 30 });
has backlog => (is => 'rw', isa => 'ArrayRef', default => sub { [] });

sub backlog_events {
    my $self = shift;
    reverse grep defined, @{$self->backlog};
}

after 'publish' => sub {
    my ($self, @events) = @_;
    my @new_backlog = (reverse(@events), @{$self->backlog});
    $self->backlog([ splice @new_backlog, 0, $self->backlog_length ]);
};

after 'add_subscriber' => sub {
    my ($self, $queue) = @_;
    $queue->append($self->backlog_events);
};

1;


__END__

=encoding utf-8

=for stopwords

=head1 NAME

AnyMQ::Topic::Trait::WithBacklog - AnyMQ topic trait for backlog behaviour

=head1 SYNOPSIS

  my $bus = AnyMQ->new;
  my $channel = AnyMQ::Topic->new_with_trait
     (traits => ['WithBacklog'], backlog_length => 30, bus => $bus);
  my $client = AnyMQ->new_listener($channel);

=head1 DESCRIPTION

The topic trait for L<AnyMQ> provides backlog to a topic.  newly
subscribed listeners (an <AnyMQ::Queue> object) will received the last
C<backlog_length> messages published to the topic.

=head1 ATTRIBUTES

=head2 backlog_length

How many messages are to be kept for the topic.

=head1 SEE ALSO

L<AnyMQ> L<AnyMQ::Topic>

=cut


