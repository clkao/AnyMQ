use strict;
use warnings;
use Test::More;
use AnyEvent;
use AnyMQ;
use AnyMQ::Queue;

my $tests = 3;

my $sequence = 0;

sub do_test {
    my ( $channel, $client ) = @_;
    my $seq = ++$sequence;
    my @send_events = ( { data1 => $seq }, { data2 => $seq } );

    my $cv = AE::cv;
    my $t  = AE::timer 5, 0, sub { $cv->croak( "timeout" ); };

    my $pub = AnyMQ->topic( $channel );
    my $sub = AnyMQ->new_listener( $pub );
    $sub->poll_once(sub {
                        is $_[0]{data1}, $seq
                    });
    $sub->timeout(1);
    $sub->on_timeout(sub {
                       isa_ok($_[0], 'AnyMQ::Queue');
                       like($_[1], qr'timeout');
                       $_[0]->destroyed(1);
                       $cv->send(1);
                   },
               );
    # Publish events before the client has connected.
    $pub->publish( $_ ) for @send_events;
    $cv->recv;
    ok( $sub->destroyed );
}

plan tests => 4 * $tests;
do_test( 'comet', 'client_id' ) for 1 .. $tests;
