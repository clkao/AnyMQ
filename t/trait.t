use strict;
use Test::More;
use AnyMQ;

our ($built, $demolished) = (0, 0);
{
    package AnyMQ::Trait::Test;
    use Moose::Role;
    use Test::More;

    sub BUILD {}; after 'BUILD' => sub {
        $main::built++;
    };

    sub DEMOLISH {}; after 'DEMOLISH' => sub {
        $main::demolished++;
    };

}

my $bus = AnyMQ->new_with_traits( traits => ['Test']);

ok($bus->DOES('AnyMQ::Trait::Test'));

ok($built);
undef $bus;
ok($demolished);
done_testing;
