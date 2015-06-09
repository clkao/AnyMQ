use inc::Module::Install;
name 'AnyMQ';
all_from 'lib/AnyMQ.pm';
readme_from 'lib/AnyMQ.pm';
build_requires 'Test::More';

requires 'Moo', '2';
requires 'MooX::Traits';
requires 'MooX::HandlesVia';
requires 'Types::Standard';
requires 'AnyEvent';

test_requires 'Test::Requires';

auto_include_deps;

auto_set_repository;
WriteAll;
