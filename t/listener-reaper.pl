use strict;
use Test::More;
use AnyMQ;
use AnyMQ::Topic;
my $bus = AnyMQ->new;

my $channel = AnyMQ::Topic->new
     (bus => $bus, reaper_interval => 1);

my $cv = AE::cv;
my $client = AnyMQ->new_listener($channel);
$client->on_error( sub { $_[0]->destroyed(1); $cv->send });
$client->poll(sub { die });

$channel->publish({ data => 1});

$cv->recv;
ok($client->destroyed, 'client is destroyed');
ok(!$channel->has_no_listeners, 'listener still registered with topic');

my $cv = AE::cv;
my $w; $w = AnyEvent->timer(after => 2, cb => sub { $cv->send });

$cv->recv;

ok($channel->has_no_listeners, 'listener automatically reapped');

done_testing;
