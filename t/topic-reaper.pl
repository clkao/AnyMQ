use strict;
use Test::More;
use AnyMQ;
use AnyMQ::Topic;
my $bus = AnyMQ->new;

sub do_test {
    my $channel = $bus->topic({ name => 'test',
                                recycle => 1 });

    my $cv = AE::cv;
    my $client = AnyMQ->new_listener($channel);
    $client->on_error( sub { $_[0]->destroyed(1); $cv->send });
    $client->poll(sub { die });

    $channel->publish({ data => 1});
    $channel->publish({ data => 2});

    $cv->recv;
    ok($client->destroyed, 'client is destroyed');
    ok($channel->has_no_listeners, 'listener destroyed');
}

do_test();

is_deeply([keys %{$bus->topics}], [], 'channel destroyed when all listeners are gone');

done_testing;
