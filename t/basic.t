use Test::More;
use AnyMQ::MQ;

my $channel  = 'test1';

my $clients = 5;
my $inc     = 0;

for my $client ( 1 .. $clients ) {
    my $sub = AnyMQ::MQ->instance( $channel );
    $sub->poll_once($client, sub { $inc++ });
}

my $pub = AnyMQ::MQ->instance( $channel );
$pub->publish({ data => 'hello' });

is( $inc, $clients, 'messagequeue publish' );

done_testing;
