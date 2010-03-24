use strict;
use warnings;
use Test::More;
use AnyEvent;
use AnyMQ;
use AnyMQ::Queue;

my $tests = 2;

my $sequence = 0;

sub do_test {
    my ( $channel, $client ) = @_;
    my $seq = ++$sequence;
    my @send_events = ( { data1 => $seq }, { data2 => $seq }, { data3 => $seq } );

    my $cv = AE::cv;
    my $t  = AE::timer 5, 0, sub { $cv->croak( "timeout" ); };

    my $pub = AnyMQ->topic( $channel );
    my $sub = AnyMQ->new_listener( $pub );
    $sub->on_error(sub {
                       my ($queue, $error, @msg) = @_;
                       $queue->persistent(0);
                       $queue->append(@msg);
                   });
    $sub->poll(sub {
                   if ($_[0]{data2}) {
                       die "poll fail";
                   }
                   is $_[0]{data1}, $seq
               });
    $sub->timeout(1);
    $sub->on_timeout(sub {
                       isa_ok($_[0], 'AnyMQ::Queue');
                       ok(1, 'timeout triggered after downgrade');
                       like($_[1], qr'timeout');
                       $cv->send(1);
                   },
               );
    # Publish events before the client has connected.
    $pub->publish( $_ ) for @send_events;
    $cv->recv;
    ok( !$sub->destroyed );
    $cv = AE::cv;
    $sub->on_timeout(undef);
    $sub->poll_once(sub {
                        my @events = @_;
                        is_deeply \@events, [@send_events[1,2]], "got events";
                        $cv->send;
                    });
    $cv->recv;

}

plan tests => 6 * $tests;
do_test( 'comet', 'client_id' ) for 1 .. $tests;
