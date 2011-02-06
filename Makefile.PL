use inc::Module::Install;
name 'AnyMQ';
all_from 'lib/AnyMQ.pm';
readme_from 'lib/AnyMQ.pm';
build_requires 'Test::More';
requires 'Any::Moose';
requires 'MouseX::NativeTraits';
requires 'AnyEvent';
requires_any_moose 'X::Traits';

test_requires 'Test::Requires';

auto_include_deps;
author_tests('xt');
auto_set_repository;
WriteAll;
