
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Yet Another IRC Bot",
  "AUTHOR" => "Hyungsuk Hong <hshong\@perl.kr>",
  "BUILD_REQUIRES" => {
    "Test::MockObject::Extends" => 0,
    "Test::More" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Hongbot",
  "EXE_FILES" => [
    "bin/hongbot"
  ],
  "LICENSE" => "perl",
  "NAME" => "Hongbot",
  "PREREQ_PM" => {
    "AnyEvent" => 0,
    "AnyEvent::HTTP" => 0,
    "AnyEvent::IRC::Client" => 0,
    "Config::General" => 0,
    "Getopt::Long::Descriptive" => 0,
    "Moose" => 0,
    "MooseX::Role::Pluggable" => 0,
    "MooseX::Role::Pluggable::Plugin" => 0,
    "Pod::Usage" => 0,
    "Time::HiRes" => 0,
    "URI" => 0,
    "namespace::autoclean" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.0.1",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



