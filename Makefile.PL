use inc::Module::Install;

name     'Gearman-XS-Declare';
all_from 'lib/Gearman/XS/Declare.pm';
author   'Cornelius <cornelius.howl@gmail.com>';
license  'perl';

build_requires 'Test::More';

requires 
        'Gearman::XS::Worker' => 0,
        'Exporter::Lite' => 0,
        'Gearman::XS' => 0;

auto_install;

WriteAll;

