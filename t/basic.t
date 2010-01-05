use Test::More;
use strict;
use AnyMQ;
use AnyMQ::Queue;

my $channel  = 'test1';

my $clients = 5;
my $inc     = 0;

my $mq = AnyMQ->instance( $channel );

for my $client ( 1 .. $clients ) {
    my $sub = AnyMQ::Queue->instance( $client, $mq );
    $sub->poll_once(sub { $inc++ });
}

$mq->publish({ data => 'hello' });

is( $inc, $clients, 'messagequeue publish' );

done_testing;
