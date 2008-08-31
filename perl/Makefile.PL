require 5.006;
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  DISTNAME  => 'Data-Rx',
  NAME      => 'Data::Rx',
  AUTHOR    => 'Ricardo SIGNES <rjbs@cpan.org>',
  ABSTRACT  => 'perl implementation of Rx schema system',
  VERSION   => '0.001',
  EXE_FILES => [ qw() ],
  (eval { ExtUtils::MakeMaker->VERSION(6.21) } ? (LICENSE => 'perl') : ()),
  PREREQ_PM    => {
    "Scalar::Util" => '0',
    "File::Find::Rule" => '0',
    "Number::Tolerant" => '0',
    "JSON::XS" => '0',
    "Carp" => '0',
    "Test::More" => '0',
    "List::Util" => '0',
    "autodie" => '0',
    "Module::Pluggable::Object" => '0',
  },
);
