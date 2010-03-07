use strict;
use warnings;
use Test::More;
use AnyMQ;
use AnyMQ::Queue;

my $channel  = 'test';

my $clients = 5;
my $inc     = 0;

my $mq = AnyMQ->topic( $channel );

for my $client ( 1 .. $clients ) {
    my $sub = AnyMQ->new_listener( $mq );
    $sub->poll( sub {
        for ( @_ ) {
            ok exists $_->{data}, "check the message received.";
            $inc++;
        }
    } );
}

$mq->publish({ data => 'hello' });
is( $inc, $clients, 'messagequeue publish and poll(1)' );

$mq->publish({ data => 'hello, again' });
is( $inc, $clients * 2, 'messagequeue publish and poll(2)' );

done_testing;
