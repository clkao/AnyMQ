use inc::Module::Install;
name 'AnyMQ';
all_from 'lib/AnyMQ.pm';
readme_from 'lib/AnyMQ.pm';
build_requires 'Test::More';
requires 'Moose' => '0.99';
requires 'MooseX::Traits';
requires 'AnyEvent';
test_requires 'Test::Requires';

auto_include_deps;
author_tests('xt');
auto_set_repository;
WriteAll;
