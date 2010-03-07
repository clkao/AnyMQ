use Test::More;
use strict;
use Test::Requires qw(Test::Memory::Cycle);
use AnyMQ;
use AnyMQ::Queue;

my $channel  = 'test1';

my $client_id = rand(1);

my $topic = AnyMQ->topic( $channel );

my $sub = AnyMQ->new_listener( $topic );
$sub->poll_once(sub { ok(1, 'got message') });

memory_cycle_ok( $sub, 'no leaks' );

$topic->publish({ data => 'hello' });

memory_cycle_ok( $sub, 'no leaks in subscriber' );
memory_cycle_ok( $topic, 'no leaks in publisher' );

# We''re actually relying on the poll_once test, hacky but not sure how to
# verify

$sub->poll(sub { });

memory_cycle_ok( $sub, 'no leaks in subscriber' );
memory_cycle_ok( $topic, 'no leaks in publisher' );

done_testing;
