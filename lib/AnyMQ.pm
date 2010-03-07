package AnyMQ;
use strict;
use 5.008_001;
our $VERSION = '0.28';

use AnyEvent;
use Moose;
use AnyMQ::Topic;
use AnyMQ::Queue;

with 'MooseX::Traits';

has '+_trait_namespace' => (default => 'AnyMQ::Trait');

has topics => (is => "ro", isa => "HashRef[AnyMQ::Topic]",
               default => sub { {} });

my $DEFAULT_BUS;

sub topic {
    my ($self, $name) = @_;
    unless (ref($self)) {
        $self = ($DEFAULT_BUS ||= $self->new);
    }

    $self->topics->{$name} ||= $self->new_topic( $name );
}

sub new_topic {
    my ($self, $name) = @_;
    AnyMQ::Topic->new( name => $name,
                       bus  => $self );
}

sub new_listener {
    my $self = shift;
    unless (ref($self)) {
        $self = ($DEFAULT_BUS ||= $self->new);
    }

    my $listener = AnyMQ::Queue->new;
    $listener->subscribe(@_) if @_;
    return $listener;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__

=encoding utf-8

=for stopwords

=head1 NAME

AnyMQ - Non-blocking message queue system based on AnyEvent

=head1 SYNOPSIS

  use AnyMQ;
  my $mq = AnyMQ->topic('Foo'); # gets an AnyMQ::Topic object
  $mq->publish({ message => 'Hello world'});

  #  bind to external message queue servers using traits.
  #  my $bus = AnyMQ->new_with_traits(traits => ['AMQP'],
  #                                   host   => 'localhost',
  #                                   port   => 5672,
  #                                   user   => 'guest',
  #                                   pass   => 'guest',
  #                                   vhost  => '/',
  #                                   exchange => '');
  #  my $mq = $bus->topic('foo')

  $mq->publish({ message => 'Hello world'});

  # $bus->new_listener('client_id', $mq);

=head1 DESCRIPTION

AnyMQ is message queue system based on AnyEvent.  It can store all
messages in memory or use external message queue servers.

Messages are published to L<AnyMQ::Topic>, and consumed with
L<AnyMQ::Queue>.

=head1 METHODS

=head2 new

Returns a new L<AnyMQ> object, which is a message bus that can
associate with arbitrary L<AnyMQ::Topic> and consumed by
L<AnyMQ::Queue>

=head2 topic($name)

Returns a L<AnyMQ::Topic> with given name.  If called as class method,
the default bus will be used.

=head2 new_topic($name)

Creates and returns a new L<AnyMQ::Topic> object with given name.
This should not be called directly.

=head2 new_listener(@topic)

Returns a new L<AnyMQ::Queue> object, and subscribes to the optional
given topic.  If called as class method, the default bus will be used.

=head1 AUTHORS

Tatsuhiko Miyagawa
Chia-liang Kao

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<AnyMQ::Topic>, L<AnyMQ::Queue>

=cut
