package AnyMQ;
use strict;
use 5.008_001;
our $VERSION = '0.01';

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

sub instance {
    my $self = shift;
    warn "deprecated, use ->topic(name)";
    $self->topic(@_);
}

sub topic_constructor_args {
    return ();
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

AnyMQ -

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
