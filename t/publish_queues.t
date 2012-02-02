use strict;
use Test::More;
use AnyMQ;
use AnyMQ::Topic;

my $bus = AnyMQ->new;

my $t1 = AnyMQ::Topic->new(
    bus => $bus,
    publish_to_queues => 1,
);
test_topic($t1);

my $t2 = AnyMQ::Topic->new(
    bus => $bus,
    publish_to_queues => 0,
);
test_topic($t2);

sub test_topic {
    my ($channel) = @_;

    my $client = AnyMQ->new_listener($channel);

    my $events = 0;
    $client->poll(sub { $events++; });

    $channel->publish({ data => 1});

    my $expected = $channel->publish_to_queues ? 1 : 0;
    is($events, $expected, "Got expected events published to queues");
}

done_testing;
