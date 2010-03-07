use Test::More;
use strict;
use AnyMQ;
use AnyMQ::Queue;

my $channel  = 'test1';

my $clients = 5;
my $inc     = 0;

my $mq = AnyMQ->topic( $channel );

for my $client ( 1 .. $clients ) {
    my $sub = AnyMQ->new_listener( $mq );
    $sub->poll_once(sub { $inc++ });
}

$mq->publish({ data => 'hello' });

is( $inc, $clients, 'messagequeue publish' );

done_testing;
