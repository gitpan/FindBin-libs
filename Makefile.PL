use ExtUtils::MakeMaker;

WriteMakefile
(
	NAME            => 'FindBin::libs',
	VERSION         => '1.00',
	ABSTRACT_FROM	=> 'lib/FindBin/libs.pm',
	PREREQ_PM =>
	{
		# standard distro, particular versions 
		# are unlikely to cause pain.

		strict       => 0,
		warnings     => 0,
		Carp         => 0,
		Cwd          => 0,
		FindBin      => 0,
	},
);
