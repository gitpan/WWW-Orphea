# $Id: Makefile.PL,v 1.4 2005/05/02 16:04:21 rousse Exp $

use ExtUtils::MakeMaker;
use ExtUtils::MakeMaker::Coverage;

WriteMakefile(
    NAME          => 'WWW::Orphea',
    VERSION_FROM  => 'lib/WWW/Orphea.pm',
    ABSTRACT_FROM => 'lib/WWW/Orphea.pm',
    AUTHOR        => 'Guillaume Rousse <grousse@cpan.org>',
    EXE_FILES     => [ 'bin/fetch-orphea-images' ],
    PREREQ_PM     => {
	'WWW::Mechanize' => 0.5,
	'Getopt::Long'   => 0,
	'Test::More'     => 0,
	'Test::URI'      => 0,
    },
    dist           => {
	COMPRESS => 'gzip -9f',
	SUFFIX   => 'gz',
    },
    clean          => {
	FILES => 'WWW-Orphea-*'
    },
);
