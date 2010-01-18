use Test::More;
use Test::Requires qw(Test::Memory::Cycle);
use AnyMQ;
use AnyMQ::Queue;

my $channel  = 'test1';

my $client_id = rand(1);

my $pub = AnyMQ->topic( $channel );

my $sub = AnyMQ::Queue->instance( $client_id, $pub );
$sub->poll_once(sub { ok(1, 'got message') });

memory_cycle_ok( $sub, 'no leaks' );

$pub->publish({ data => 'hello' });

memory_cycle_ok( $sub, 'no leaks in subscriber' );
memory_cycle_ok( $pub, 'no leaks in publisher' );

# We''re actually relying on the poll_once test, hacky but not sure how to
# verify

done_testing;
