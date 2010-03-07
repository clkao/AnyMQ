use strict;
use Test::More;
use AnyMQ;
use AnyMQ::Topic;
my $bus = AnyMQ->new;

my $channel = AnyMQ::Topic->new_with_traits
     (traits => ['WithBacklog'], backlog_length => 30, bus => $bus);

$channel->publish({ data => 1});
$channel->publish({ data => 2});

my $client = AnyMQ->new_listener($channel);

my $q = AE::cv;
$client->poll_once(sub {
                       my @msg = @_;
                       is( scalar @msg, 2);
                       is_deeply(\@msg, [{data => 1}, {data => 2}]);
                       $q->send();
                   });
$q->recv;
done_testing;
