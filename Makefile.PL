use inc::Module::Install;
name 'AnyMQ';
all_from 'lib/AnyMQ.pm';
readme_from 'lib/AnyMQ.pm';
build_requires 'Test::More';
requires 'Any::Moose';
requires 'MouseX::NativeTraits';
requires 'AnyEvent';

if (my $moose = $ENV{ANY_MOOSE}) {
    requires $moose.'X::Traits';
}
requires_any_moose 'X::Traits';

test_requires 'Test::Requires';

auto_include_deps;

auto_set_repository;
WriteAll;
