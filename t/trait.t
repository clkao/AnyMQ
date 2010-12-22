use strict;
use Test::More;
use AnyMQ;

our ($built, $demolished) = (0, 0);
{
    package AnyMQ::Trait::Test;
    use Any::Moose "::Role";
    use Test::More;

    sub BUILD {}; after 'BUILD' => sub {
        $main::built++;
    };

    sub DEMOLISH {}; after 'DEMOLISH' => sub {
        $main::demolished++;
    };

}

my $bus = AnyMQ->new_with_traits( traits => ['Test']);

# Mouse hasn't supported UNIVERSAL::DOES yet
ok($bus->does('AnyMQ::Trait::Test') || $bus->isa('AnyMQ::Trait::Test'));

ok($built);
undef $bus;
ok($demolished);
done_testing;
