# $Id: Makefile.PL,v 1.3 2004/04/08 08:00:02 guillaume Exp $

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'WWW::Orphea',
    VERSION_FROM => 'lib/WWW/Orphea.pm',
    EXE_FILES    => [ 'bin/fetch-orphea-images' ],
    AUTHOR       => 'Guillaume Rousse <grousse@cpan.org>',
    PREREQ_PM    => {
	'WWW::Mechanize' => 0.5,
	'Getopt::Long'   => 0,
	'Test::URI'      => 0
    }
);
